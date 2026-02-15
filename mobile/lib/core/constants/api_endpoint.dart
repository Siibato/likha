class ApiEndpoint<T> {
  final String path;
  final T Function(dynamic json) fromJson;

  const ApiEndpoint(this.path, this.fromJson);

  factory ApiEndpoint.fromModel(
    String path,
    T Function(Map<String, dynamic>) modelFromJson,
  ) {
    return ApiEndpoint(
      path,
      (dynamic json) => modelFromJson(json as Map<String, dynamic>),
    );
  }
}
