import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabase {
  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<void> putItem(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await Hive.openBox<Map>('table_$table');
    await box.put(id, data);
  }

  Future<Map<String, dynamic>?> getItem(String table, String id) async {
    final box = await Hive.openBox<Map>('table_$table');
    final item = box.get(id);
    return item != null ? Map<String, dynamic>.from(item) : null;
  }

  Future<List<Map<String, dynamic>>> getAllItems(String table) async {
    final box = await Hive.openBox<Map>('table_$table');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> deleteItem(String table, String id) async {
    final box = await Hive.openBox<Map>('table_$table');
    await box.delete(id);
  }
}
