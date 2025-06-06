abstract class DataSerializer<T> {
  Map<String, dynamic> toMap(T object);
  T fromMap(Map<String, dynamic> map);
  String get tableName;
}
