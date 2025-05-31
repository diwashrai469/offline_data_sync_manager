abstract class SyncApiAdapter {
  Future<void> sendInsert(String table, Map<String, dynamic> data);
  Future<void> sendUpdate(String table, Map<String, dynamic> data);
  Future<void> sendDelete(String table, Map<String, dynamic> data);
}
