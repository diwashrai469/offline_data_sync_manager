import 'package:flutter/foundation.dart';
import 'package:offline_data_sync_manager/models/sync_status.dart';

import '../services/sync_service.dart';
import '../services/connectivity_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final ConnectivityService _connectivityService;

  SyncStatus _status = SyncStatus(
    state: SyncState.idle,
    pendingOperations: 0,
    lastSync: DateTime.now(),
    isConnected: false,
  );

  SyncStatus get status => _status;

  SyncProvider({
    required SyncService syncService,
    required ConnectivityService connectivityService,
  }) : _syncService = syncService,
       _connectivityService = connectivityService {
    _initializeListeners();
  }

  void _initializeListeners() {
    _connectivityService.connectivityStream.listen((isConnected) {
      _updateStatus(isConnected: isConnected);
    });

    _syncService.pendingOperationsStream.listen((count) {
      _updateStatus(pendingOperations: count);
    });

    _syncService.syncStatusStream.listen((message) {
      SyncState state = SyncState.idle;
      if (message.contains('Syncing')) {
        state = SyncState.syncing;
      } else if (message.contains('completed')) {
        state = SyncState.success;
      } else if (message.contains('failed') || message.contains('Error')) {
        state = SyncState.error;
      }

      _updateStatus(
        state: state,
        message: message,
        lastSync: state == SyncState.success ? DateTime.now() : null,
      );
    });
  }

  void _updateStatus({
    SyncState? state,
    String? message,
    int? pendingOperations,
    DateTime? lastSync,
    bool? isConnected,
  }) {
    _status = _status.copyWith(
      state: state,
      message: message,
      pendingOperations: pendingOperations,
      lastSync: lastSync,
      isConnected: isConnected,
    );
    notifyListeners();
  }

  Future<void> manualSync() async {
    await _syncService.sync();
  }

  Future<void> clearPendingOperations() async {
    await _syncService.clearPendingOperations();
  }
}
