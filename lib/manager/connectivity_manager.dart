import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_data_sync_manager/manager/sync_manager.dart';

void monitorConnection(SyncManager manager) {
  Connectivity().onConnectivityChanged.listen(
    (ConnectivityResult result) {
          if (result != ConnectivityResult.none) {
            manager.syncQueue();
          }
        }
        as void Function(List<ConnectivityResult> event)?,
  );
}
