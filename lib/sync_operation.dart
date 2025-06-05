import 'package:uuid/uuid.dart';

enum SyncOperationType { create, update, delete }

class SyncOperation {
  final String id;
  final String collectionName;
  final String? documentId;
  final SyncOperationType operationType;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;
  final String? errorMessage;

  SyncOperation({
    String? id,
    required this.collectionName,
    this.documentId,
    required this.operationType,
    this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.errorMessage,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection_name': collectionName,
      'document_id': documentId,
      'operation_type': operationType.index,
      'data': data != null ? _encodeData(data!) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'],
      collectionName: map['collection_name'],
      documentId: map['document_id'],
      operationType: SyncOperationType.values[map['operation_type']],
      data: map['data'] != null ? _decodeData(map['data']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      retryCount: map['retry_count'] ?? 0,
      errorMessage: map['error_message'],
    );
  }

  SyncOperation copyWith({
    String? id,
    String? collectionName,
    String? documentId,
    SyncOperationType? operationType,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      collectionName: collectionName ?? this.collectionName,
      documentId: documentId ?? this.documentId,
      operationType: operationType ?? this.operationType,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static String _encodeData(Map<String, dynamic> data) {
    // Simple JSON encoding for SQLite storage
    return data.toString();
  }

  static Map<String, dynamic>? _decodeData(String data) {
    // This is a simplified approach. In production, use proper JSON encoding/decoding
    try {
      // For now, returning null. Implement proper JSON parsing based on your needs
      return null;
    } catch (e) {
      return null;
    }
  }
}
