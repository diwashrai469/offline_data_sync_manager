class SyncResult {
  final bool success;
  final String? error;
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final List<String> failedOperationIds;

  const SyncResult({
    required this.success,
    this.error,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.failedOperationIds,
  });

  factory SyncResult.success({
    required int totalOperations,
    required int successfulOperations,
  }) {
    return SyncResult(
      success: true,
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      failedOperations: 0,
      failedOperationIds: [],
    );
  }

  factory SyncResult.failure({
    required String error,
    required int totalOperations,
    required int successfulOperations,
    required int failedOperations,
    required List<String> failedOperationIds,
  }) {
    return SyncResult(
      success: false,
      error: error,
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      failedOperations: failedOperations,
      failedOperationIds: failedOperationIds,
    );
  }
}
