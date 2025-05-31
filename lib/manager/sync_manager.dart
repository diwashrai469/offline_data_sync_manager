import 'dart:convert';
import 'package:offline_data_sync_manager/adapter/sync_api_adapter.dart';
import 'package:offline_data_sync_manager/database/local_database.dart';
import 'package:offline_data_sync_manager/models/sync_model.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SyncManager {
  final SyncApiAdapter api;
  final LocalDatabase localDb;
  final _uuid = Uuid();

  SyncManager({required this.api, required this.localDb});

  Future<void> init() async {
    await localDb.init();
    await Hive.openBox<String>('sync_queue');
  }

  Future<void> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final id = data['id'] ?? _uuid.v4();
    data['id'] = id;
    await localDb.putItem(table, id, data);
    await _queueSync('insert', table, data);
  }

  Future<void> update({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final id = data['id'];
    if (id == null) throw Exception("Missing ID for update");
    await localDb.putItem(table, id, data);
    await _queueSync('update', table, data);
  }

  Future<void> delete({required String table, required String id}) async {
    await localDb.deleteItem(table, id);
    await _queueSync('delete', table, {'id': id});
  }

  Future<void> syncQueue() async {
    final queue = Hive.box<String>('sync_queue');
    final entries = queue.toMap();
    for (final key in entries.keys) {
      final sync = SyncModel.fromJson(jsonDecode(entries[key]!));
      try {
        switch (sync.action) {
          case 'insert':
            await api.sendInsert(sync.table, sync.data);
            break;
          case 'update':
            await api.sendUpdate(sync.table, sync.data);
            break;
          case 'delete':
            await api.sendDelete(sync.table, sync.data);
            break;
        }
        await queue.delete(key);
      } catch (_) {
        // Retry later
      }
    }
  }

  Future<void> _queueSync(
    String action,
    String table,
    Map<String, dynamic> data,
  ) async {
    final sync = SyncModel(
      id: _uuid.v4(),
      table: table,
      action: action,
      data: data,
      timestamp: DateTime.now(),
    );
    final queue = Hive.box<String>('sync_queue');
    await queue.put(sync.id, jsonEncode(sync.toJson()));
  }
}
