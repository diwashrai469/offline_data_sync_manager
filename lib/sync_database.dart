import 'dart:async';
import 'package:offline_data_sync_manager/sync_operation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SyncDatabase {
  static Database? _database;
  static const String _tableName = 'sync_operations';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sync_operations.db');
    return await openDatabase(path, version: 1, onCreate: _createTable);
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        collection_name TEXT NOT NULL,
        document_id TEXT,
        operation_type INTEGER NOT NULL,
        data TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');
  }

  Future<String> insertOperation(SyncOperation operation) async {
    final db = await database;
    await db.insert(_tableName, operation.toMap());
    return operation.id;
  }

  Future<List<SyncOperation>> getAllOperations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => SyncOperation.fromMap(maps[i]));
  }

  Future<List<SyncOperation>> getOperationsByCollection(
    String collection,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'collection_name = ?',
      whereArgs: [collection],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => SyncOperation.fromMap(maps[i]));
  }

  Future<void> updateOperation(SyncOperation operation) async {
    final db = await database;
    await db.update(
      _tableName,
      operation.toMap(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  Future<void> deleteOperation(String operationId) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [operationId]);
  }

  Future<void> deleteOperationsByIds(List<String> operationIds) async {
    if (operationIds.isEmpty) return;

    final db = await database;
    final placeholders = operationIds.map((_) => '?').join(',');
    await db.delete(
      _tableName,
      where: 'id IN ($placeholders)',
      whereArgs: operationIds,
    );
  }

  Future<int> getOperationCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAllOperations() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
