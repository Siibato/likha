import 'package:json_annotation/json_annotation.dart';

part 'fetch_response_model.g.dart';

/// Response from /sync/fetch endpoint (paginated records)
@JsonSerializable()
class FetchResponseModel {
  /// Entity types with their full records
  final Map<String, List<dynamic>> entities;

  /// Cursor for resuming pagination (null if no more records)
  final String? cursor;

  /// Whether there are more records to fetch
  @JsonKey(name: 'has_more')
  final bool hasMore;

  FetchResponseModel({
    required this.entities,
    this.cursor,
    required this.hasMore,
  });

  factory FetchResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FetchResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$FetchResponseModelToJson(this);
}
