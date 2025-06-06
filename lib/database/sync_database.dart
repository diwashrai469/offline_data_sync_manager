import 'dart:convert';
import 'package:offline_data_sync_manager/models/sync_operation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SyncDatabase {
  static Database? _database;
  static const String _databaseName = 'sync_operations.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_operations (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        record_id TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON sync_operations(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_table_name ON sync_operations(table_name)
    ''');
  }

  Future<void> insertOperation(SyncOperation operation) async {
    final db = await database;
    final operationMap = operation.toMap();
    operationMap['data'] = jsonEncode(operationMap['data']);

    await db.insert(
      'sync_operations',
      operationMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncOperation>> getPendingOperations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_operations',
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) {
      final operationMap = Map<String, dynamic>.from(map);
      operationMap['data'] = jsonDecode(operationMap['data']);
      return SyncOperation.fromMap(operationMap);
    }).toList();
  }

  Future<void> deleteOperation(String operationId) async {
    final db = await database;
    await db.delete(
      'sync_operations',
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  Future<void> updateRetryCount(String operationId, int retryCount) async {
    final db = await database;
    await db.update(
      'sync_operations',
      {'retry_count': retryCount},
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  Future<int> getPendingOperationsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_operations',
    );
    return result.first['count'] as int;
  }

  Future<void> clearAllOperations() async {
    final db = await database;
    await db.delete('sync_operations');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
