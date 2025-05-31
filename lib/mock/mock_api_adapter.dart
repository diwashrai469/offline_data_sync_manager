import 'package:flutter/foundation.dart';
import 'package:offline_data_sync_manager/adapter/sync_api_adapter.dart';

class MockApiAdapter implements SyncApiAdapter {
  @override
  Future<void> sendInsert(String table, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('Mock Insert to $table: $data');
    }
  }

  @override
  Future<void> sendUpdate(String table, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('Mock Update to $table: $data');
    }
  }

  @override
  Future<void> sendDelete(String table, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('Mock Delete from $table: $data');
    }
  }
}
