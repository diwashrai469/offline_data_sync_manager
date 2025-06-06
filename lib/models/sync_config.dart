class SyncConfig {
  final Duration syncInterval;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final bool enableAutoSync;
  final bool enableBatching;
  final int batchSize;
  final Duration connectivityCheckInterval;

  const SyncConfig({
    this.syncInterval = const Duration(minutes: 5),
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.enableAutoSync = true,
    this.enableBatching = true,
    this.batchSize = 10,
    this.connectivityCheckInterval = const Duration(seconds: 5),
  });
}
