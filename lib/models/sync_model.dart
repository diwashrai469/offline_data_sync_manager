class SyncModel {
  final String id;
  final String table;
  final String action;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncModel({
    required this.id,
    required this.table,
    required this.action,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'action': action,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SyncModel.fromJson(Map<String, dynamic> json) => SyncModel(
    id: json['id'],
    table: json['table'],
    action: json['action'],
    data: Map<String, dynamic>.from(json['data']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}
