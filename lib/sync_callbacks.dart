import 'package:offline_data_sync_manager/sync_operation.dart';
import 'package:offline_data_sync_manager/sync_result.dart';

abstract class SyncCallbacks {
  /// Called when sync process starts
  void onSyncStarted();

  /// Called when sync process completes
  void onSyncCompleted(SyncResult result);

  /// Called when a single operation syncs successfully
  void onOperationSyncSuccess(SyncOperation operation);

  /// Called when a single operation fails to sync
  void onOperationSyncFailure(SyncOperation operation, String error);

  /// Called when the sync queue is updated
  void onQueueUpdate(int pendingOperations);

  /// Called when connectivity status changes
  void onConnectivityChanged(bool isOnline);
}
