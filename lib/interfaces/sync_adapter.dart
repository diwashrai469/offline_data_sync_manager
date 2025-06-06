abstract class SyncAdapter {
  Future<bool> create(String tableName, Map<String, dynamic> data);
  Future<bool> update(String tableName, String id, Map<String, dynamic> data);
  Future<bool> delete(String tableName, String id);
  Future<List<Map<String, dynamic>>> read(
    String tableName, {
    Map<String, dynamic>? filters,
  });
}
