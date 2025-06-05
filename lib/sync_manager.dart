import 'dart:async';
import 'dart:developer' as developer;

import 'package:offline_data_sync_manager/api_service.dart';
import 'package:offline_data_sync_manager/connectivity_service.dart';
import 'package:offline_data_sync_manager/sync_callbacks.dart';
import 'package:offline_data_sync_manager/sync_database.dart';
import 'package:offline_data_sync_manager/sync_operation.dart';
import 'package:offline_data_sync_manager/sync_result.dart';

class OfflineDataSyncManager {
  final ApiService _apiService;
  final SyncCallbacks? _callbacks;
  final SyncDatabase _syncDatabase = SyncDatabase();
  final ConnectivityService _connectivityService = ConnectivityService();

  Timer? _syncTimer;
  bool _isSyncing = false;
  final Duration _syncInterval;
  final int _maxRetryAttempts;

  StreamSubscription? _connectivitySubscription;

  OfflineDataSyncManager({
    required ApiService apiService,
    SyncCallbacks? callbacks,
    Duration syncInterval = const Duration(minutes: 1),
    int maxRetryAttempts = 3,
  }) : _apiService = apiService,
       _callbacks = callbacks,
       _syncInterval = syncInterval,
       _maxRetryAttempts = maxRetryAttempts;

  /// Initialize the sync manager
  Future<void> initialize() async {
    await _connectivityService.initialize();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      bool isOnline,
    ) {
      _callbacks?.onConnectivityChanged(isOnline);
      if (isOnline) {
        _triggerSync();
      }
    });

    // Start periodic sync
    _startPeriodicSync();

    // Update queue count
    await _updateQueueCount();
  }

  /// Create operation - works online/offline
  Future<String?> create(String collection, Map<String, dynamic> data) async {
    if (_connectivityService.isOnline) {
      try {
        final documentId = await _apiService.create(collection, data);
        developer.log('Created document online: $documentId');
        return documentId;
      } catch (e) {
        developer.log('Failed to create online, queuing: $e');
        // Fall back to offline mode
      }
    }

    // Queue for later sync
    final operation = SyncOperation(
      collectionName: collection,
      operationType: SyncOperationType.create,
      data: data,
    );

    await _syncDatabase.insertOperation(operation);
    await _updateQueueCount();

    developer.log('Queued create operation: ${operation.id}');
    return operation.id;
  }

  /// Update operation - works online/offline
  Future<void> update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    if (_connectivityService.isOnline) {
      try {
        await _apiService.update(collection, documentId, data);
        developer.log('Updated document online: $documentId');
        return;
      } catch (e) {
        developer.log('Failed to update online, queuing: $e');
        // Fall back to offline mode
      }
    }

    // Queue for later sync
    final operation = SyncOperation(
      collectionName: collection,
      documentId: documentId,
      operationType: SyncOperationType.update,
      data: data,
    );

    await _syncDatabase.insertOperation(operation);
    await _updateQueueCount();

    developer.log('Queued update operation: ${operation.id}');
  }

  /// Delete operation - works online/offline
  Future<void> delete(String collection, String documentId) async {
    if (_connectivityService.isOnline) {
      try {
        await _apiService.delete(collection, documentId);
        developer.log('Deleted document online: $documentId');
        return;
      } catch (e) {
        developer.log('Failed to delete online, queuing: $e');
        // Fall back to offline mode
      }
    }

    // Queue for later sync
    final operation = SyncOperation(
      collectionName: collection,
      documentId: documentId,
      operationType: SyncOperationType.delete,
    );

    await _syncDatabase.insertOperation(operation);
    await _updateQueueCount();

    developer.log('Queued delete operation: ${operation.id}');
  }

  /// Get pending operations count
  Future<int> getPendingOperationsCount() async {
    return await _syncDatabase.getOperationCount();
  }

  /// Manually trigger sync
  Future<SyncResult> sync({bool force = false}) async {
    if (_isSyncing && !force) {
      return SyncResult.failure(
        error: 'Sync already in progress',
        totalOperations: 0,
        successfulOperations: 0,
        failedOperations: 0,
        failedOperationIds: [],
      );
    }

    if (!_connectivityService.isOnline) {
      return SyncResult.failure(
        error: 'No internet connection',
        totalOperations: 0,
        successfulOperations: 0,
        failedOperations: 0,
        failedOperationIds: [],
      );
    }

    return await _performSync();
  }

  Future<SyncResult> _performSync() async {
    _isSyncing = true;
    _callbacks?.onSyncStarted();

    try {
      final operations = await _syncDatabase.getAllOperations();

      if (operations.isEmpty) {
        final result = SyncResult.success(
          totalOperations: 0,
          successfulOperations: 0,
        );
        _callbacks?.onSyncCompleted(result);
        return result;
      }

      int successCount = 0;
      int failCount = 0;
      List<String> failedIds = [];
      List<String> successfulIds = [];

      for (final operation in operations) {
        try {
          await _syncSingleOperation(operation);
          successCount++;
          successfulIds.add(operation.id);
          _callbacks?.onOperationSyncSuccess(operation);
        } catch (e) {
          failCount++;
          failedIds.add(operation.id);
          _callbacks?.onOperationSyncFailure(operation, e.toString());

          // Update retry count
          final updatedOperation = operation.copyWith(
            retryCount: operation.retryCount + 1,
            errorMessage: e.toString(),
          );

          if (updatedOperation.retryCount >= _maxRetryAttempts) {
            // Max retries reached, remove from queue
            successfulIds.add(operation.id);
            developer.log(
              'Max retries reached for operation ${operation.id}, removing from queue',
            );
          } else {
            // Update with new retry count
            await _syncDatabase.updateOperation(updatedOperation);
          }
        }
      }

      // Remove successful operations from database
      if (successfulIds.isNotEmpty) {
        await _syncDatabase.deleteOperationsByIds(successfulIds);
      }

      await _updateQueueCount();

      final result =
          failCount == 0
              ? SyncResult.success(
                totalOperations: operations.length,
                successfulOperations: successCount,
              )
              : SyncResult.failure(
                error: 'Some operations failed to sync',
                totalOperations: operations.length,
                successfulOperations: successCount,
                failedOperations: failCount,
                failedOperationIds: failedIds,
              );

      _callbacks?.onSyncCompleted(result);
      return result;
    } catch (e) {
      final result = SyncResult.failure(
        error: e.toString(),
        totalOperations: 0,
        successfulOperations: 0,
        failedOperations: 0,
        failedOperationIds: [],
      );
      _callbacks?.onSyncCompleted(result);
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSingleOperation(SyncOperation operation) async {
    switch (operation.operationType) {
      case SyncOperationType.create:
        if (operation.data != null) {
          await _apiService.create(operation.collectionName, operation.data!);
        }
        break;
      case SyncOperationType.update:
        if (operation.documentId != null && operation.data != null) {
          await _apiService.update(
            operation.collectionName,
            operation.documentId!,
            operation.data!,
          );
        }
        break;
      case SyncOperationType.delete:
        if (operation.documentId != null) {
          await _apiService.delete(
            operation.collectionName,
            operation.documentId!,
          );
        }
        break;
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_connectivityService.isOnline && !_isSyncing) {
        _triggerSync();
      }
    });
  }

  void _triggerSync() {
    Timer(const Duration(seconds: 1), () async {
      if (_connectivityService.isOnline && !_isSyncing) {
        await _performSync();
      }
    });
  }

  Future<void> _updateQueueCount() async {
    final count = await _syncDatabase.getOperationCount();
    _callbacks?.onQueueUpdate(count);
  }

  /// Clear all pending operations
  Future<void> clearQueue() async {
    await _syncDatabase.clearAllOperations();
    await _updateQueueCount();
  }

  /// Dispose resources
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    await _syncDatabase.close();
  }
}
