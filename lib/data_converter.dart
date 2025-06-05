abstract class DataConverter<T> {
  /// Convert local data model to API format
  Map<String, dynamic> toApiFormat(T data);

  /// Convert API response to local data model
  T fromApiFormat(Map<String, dynamic> data);

  /// Convert local data model to local storage format
  Map<String, dynamic> toLocalFormat(T data);

  /// Convert local storage data to local data model
  T fromLocalFormat(Map<String, dynamic> data);
}
