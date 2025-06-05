abstract class ApiService {
  /// Create a document in the remote service
  Future<String> create(String collection, Map<String, dynamic> data);

  /// Update a document in the remote service
  Future<void> update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  );

  /// Delete a document from the remote service
  Future<void> delete(String collection, String documentId);

  /// Get a document from the remote service
  Future<Map<String, dynamic>?> get(String collection, String documentId);

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll(String collection);

  /// Check if the service is available/reachable
  Future<bool> isServiceAvailable();
}
