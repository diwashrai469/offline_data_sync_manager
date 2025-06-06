enum SyncOperationType { create, update, delete }

class SyncOperation {
  final String id;
  final String tableName;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? recordId;

  SyncOperation({
    required this.id,
    required this.tableName,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.recordId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
      'record_id': recordId,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'],
      tableName: map['table_name'],
      type: SyncOperationType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
      retryCount: map['retry_count'] ?? 0,
      recordId: map['record_id'],
    );
  }

  SyncOperation copyWith({
    String? id,
    String? tableName,
    SyncOperationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    String? recordId,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      recordId: recordId ?? this.recordId,
    );
  }
}
