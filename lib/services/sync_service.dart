import 'dart:async';

import 'package:offline_data_sync_manager/models/sync_config.dart';
import 'package:offline_data_sync_manager/models/sync_operation.dart';

import '../database/sync_database.dart';
import '../interfaces/sync_adapter.dart';
import 'connectivity_service.dart';

class SyncService {
  final SyncDatabase _database;
  final ConnectivityService _connectivityService;
  final SyncAdapter _adapter;
  final SyncConfig _config;

  Timer? _syncTimer;
  bool _isSyncing = false;

  final StreamController<int> _pendingOperationsController =
      StreamController<int>.broadcast();
  Stream<int> get pendingOperationsStream =>
      _pendingOperationsController.stream;

  final StreamController<String> _syncStatusController =
      StreamController<String>.broadcast();
  Stream<String> get syncStatusStream => _syncStatusController.stream;

  SyncService({
    required SyncDatabase database,
    required ConnectivityService connectivityService,
    required SyncAdapter adapter,
    required SyncConfig config,
  }) : _database = database,
       _connectivityService = connectivityService,
       _adapter = adapter,
       _config = config {
    _initializeAutoSync();
  }

  void _initializeAutoSync() {
    if (_config.enableAutoSync) {
      _connectivityService.connectivityStream.listen((isConnected) {
        if (isConnected && !_isSyncing) {
          sync();
        }
      });

      _syncTimer = Timer.periodic(_config.syncInterval, (_) {
        if (_connectivityService.isConnected && !_isSyncing) {
          sync();
        }
      });
    }
  }

  Future<void> queueOperation(SyncOperation operation) async {
    await _database.insertOperation(operation);
    final count = await _database.getPendingOperationsCount();
    _pendingOperationsController.add(count);

    if (_connectivityService.isConnected && !_isSyncing) {
      sync();
    }
  }

  Future<bool> sync() async {
    if (_isSyncing || !_connectivityService.isConnected) {
      return false;
    }

    _isSyncing = true;
    _syncStatusController.add('Syncing...');

    try {
      final operations = await _database.getPendingOperations();

      if (operations.isEmpty) {
        _syncStatusController.add('No operations to sync');
        return true;
      }

      final operationsToProcess =
          _config.enableBatching
              ? operations.take(_config.batchSize).toList()
              : operations;

      bool allSuccessful = true;

      for (final operation in operationsToProcess) {
        try {
          bool success = false;

          switch (operation.type) {
            case SyncOperationType.create:
              success = await _adapter.create(
                operation.tableName,
                operation.data,
              );
              break;
            case SyncOperationType.update:
              if (operation.recordId != null) {
                success = await _adapter.update(
                  operation.tableName,
                  operation.recordId!,
                  operation.data,
                );
              }
              break;
            case SyncOperationType.delete:
              if (operation.recordId != null) {
                success = await _adapter.delete(
                  operation.tableName,
                  operation.recordId!,
                );
              }
              break;
          }

          if (success) {
            await _database.deleteOperation(operation.id);
          } else {
            final newRetryCount = operation.retryCount + 1;
            if (newRetryCount >= _config.maxRetryAttempts) {
              await _database.deleteOperation(operation.id);
              _syncStatusController.add(
                'Operation ${operation.id} failed after max retries',
              );
            } else {
              await _database.updateRetryCount(operation.id, newRetryCount);
              allSuccessful = false;
            }
          }
        } catch (e) {
          allSuccessful = false;
          _syncStatusController.add(
            'Error syncing operation ${operation.id}: $e',
          );
        }
      }

      final remainingCount = await _database.getPendingOperationsCount();
      _pendingOperationsController.add(remainingCount);

      _syncStatusController.add(
        allSuccessful ? 'Sync completed' : 'Sync completed with errors',
      );
      return allSuccessful;
    } catch (e) {
      _syncStatusController.add('Sync failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> clearPendingOperations() async {
    await _database.clearAllOperations();
    _pendingOperationsController.add(0);
  }

  void dispose() {
    _syncTimer?.cancel();
    _pendingOperationsController.close();
    _syncStatusController.close();
  }
}
