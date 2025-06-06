enum SyncState { idle, syncing, success, error, offline }

class SyncStatus {
  final SyncState state;
  final String? message;
  final int pendingOperations;
  final DateTime lastSync;
  final bool isConnected;

  const SyncStatus({
    required this.state,
    this.message,
    required this.pendingOperations,
    required this.lastSync,
    required this.isConnected,
  });

  SyncStatus copyWith({
    SyncState? state,
    String? message,
    int? pendingOperations,
    DateTime? lastSync,
    bool? isConnected,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastSync: lastSync ?? this.lastSync,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
