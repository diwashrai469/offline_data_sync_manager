import 'package:offline_data_sync_manager/database/sync_database.dart';
import 'package:offline_data_sync_manager/interfaces/data_serializer.dart';
import 'package:offline_data_sync_manager/interfaces/sync_adapter.dart';
import 'package:offline_data_sync_manager/models/sync_config.dart';
import 'package:offline_data_sync_manager/models/sync_operation.dart';
import 'package:offline_data_sync_manager/providers/sync_provider.dart';
import 'package:offline_data_sync_manager/services/connectivity_service.dart';
import 'package:offline_data_sync_manager/services/sync_service.dart';
import 'package:uuid/uuid.dart';

class SyncManager {
  late final SyncDatabase _database;
  late final ConnectivityService _connectivityService;
  late final SyncService _syncService;
  late final SyncProvider _provider;

  final SyncAdapter _adapter;
  final SyncConfig _config;

  SyncManager({required SyncAdapter adapter, SyncConfig? config})
    : _adapter = adapter,
      _config = config ?? const SyncConfig() {
    _initialize();
  }

  void _initialize() {
    _database = SyncDatabase();
    _connectivityService = ConnectivityService();
    _syncService = SyncService(
      database: _database,
      connectivityService: _connectivityService,
      adapter: _adapter,
      config: _config,
    );
    _provider = SyncProvider(
      syncService: _syncService,
      connectivityService: _connectivityService,
    );
  }

  SyncProvider get provider => _provider;
  bool get isConnected => _connectivityService.isConnected;

  Future<void> create<T>(DataSerializer<T> serializer, T object) async {
    final data = serializer.toMap(object);

    if (_connectivityService.isConnected) {
      try {
        final success = await _adapter.create(serializer.tableName, data);
        if (!success) {
          await _queueOperation(
            serializer.tableName,
            SyncOperationType.create,
            data,
          );
        }
      } catch (e) {
        await _queueOperation(
          serializer.tableName,
          SyncOperationType.create,
          data,
        );
      }
    } else {
      await _queueOperation(
        serializer.tableName,
        SyncOperationType.create,
        data,
      );
    }
  }

  Future<void> update<T>(
    DataSerializer<T> serializer,
    String id,
    T object,
  ) async {
    final data = serializer.toMap(object);

    if (_connectivityService.isConnected) {
      try {
        final success = await _adapter.update(serializer.tableName, id, data);
        if (!success) {
          await _queueOperation(
            serializer.tableName,
            SyncOperationType.update,
            data,
            recordId: id,
          );
        }
      } catch (e) {
        await _queueOperation(
          serializer.tableName,
          SyncOperationType.update,
          data,
          recordId: id,
        );
      }
    } else {
      await _queueOperation(
        serializer.tableName,
        SyncOperationType.update,
        data,
        recordId: id,
      );
    }
  }

  Future<void> delete<T>(DataSerializer<T> serializer, String id) async {
    if (_connectivityService.isConnected) {
      try {
        final success = await _adapter.delete(serializer.tableName, id);
        if (!success) {
          await _queueOperation(
            serializer.tableName,
            SyncOperationType.delete,
            {},
            recordId: id,
          );
        }
      } catch (e) {
        await _queueOperation(
          serializer.tableName,
          SyncOperationType.delete,
          {},
          recordId: id,
        );
      }
    } else {
      await _queueOperation(
        serializer.tableName,
        SyncOperationType.delete,
        {},
        recordId: id,
      );
    }
  }

  Future<List<T>> read<T>(
    DataSerializer<T> serializer, {
    Map<String, dynamic>? filters,
  }) async {
    if (_connectivityService.isConnected) {
      try {
        final results = await _adapter.read(
          serializer.tableName,
          filters: filters,
        );
        return results.map((map) => serializer.fromMap(map)).toList();
      } catch (e) {
        // If online read fails, could implement local fallback here
        throw e;
      }
    } else {
      throw Exception(
        'Offline read not implemented - requires local cache implementation',
      );
    }
  }

  Future<void> _queueOperation(
    String tableName,
    SyncOperationType type,
    Map<String, dynamic> data, {
    String? recordId,
  }) async {
    final operation = SyncOperation(
      id: const Uuid().v4(),
      tableName: tableName,
      type: type,
      data: data,
      timestamp: DateTime.now(),
      recordId: recordId,
    );

    await _syncService.queueOperation(operation);
  }

  Future<void> manualSync() async {
    await _syncService.sync();
  }

  void dispose() {
    _syncService.dispose();
    _connectivityService.dispose();
    _database.close();
  }
}
