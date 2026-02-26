import 'package:json_annotation/json_annotation.dart';

part 'manifest_response_model.g.dart';

/// Manifest entry: id + timestamp + deleted flag
@JsonSerializable()
class ManifestEntry {
  final String id;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final bool deleted;

  ManifestEntry({
    required this.id,
    required this.updatedAt,
    required this.deleted,
  });

  factory ManifestEntry.fromJson(Map<String, dynamic> json) =>
      _$ManifestEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ManifestEntryToJson(this);
}

/// Response from /sync/manifest endpoint
@JsonSerializable()
class ManifestResponseModel {
  final List<ManifestEntry> classes;
  final List<ManifestEntry> enrollments;
  final List<ManifestEntry> assessments;
  @JsonKey(name: 'assessment_questions')
  final List<ManifestEntry> assessmentQuestions;
  @JsonKey(name: 'assessment_submissions')
  final List<ManifestEntry> assessmentSubmissions;
  final List<ManifestEntry> assignments;
  @JsonKey(name: 'assignment_submissions')
  final List<ManifestEntry> assignmentSubmissions;
  @JsonKey(name: 'learning_materials')
  final List<ManifestEntry> learningMaterials;
  @JsonKey(name: 'server_time')
  final String? serverTime;

  ManifestResponseModel({
    required this.classes,
    required this.enrollments,
    required this.assessments,
    required this.assessmentQuestions,
    required this.assessmentSubmissions,
    required this.assignments,
    required this.assignmentSubmissions,
    required this.learningMaterials,
    this.serverTime,
  });

  factory ManifestResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ManifestResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ManifestResponseModelToJson(this);
}
