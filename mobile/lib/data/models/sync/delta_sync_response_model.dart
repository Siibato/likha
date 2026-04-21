import 'package:json_annotation/json_annotation.dart';

part 'delta_sync_response_model.g.dart';

/// Represents updated and deleted records for a single entity type
@JsonSerializable()
class EntityDeltas {
  final List<Map<String, dynamic>> updated;
  final List<String> deleted;

  EntityDeltas({
    required this.updated,
    required this.deleted,
  });

  factory EntityDeltas.fromJson(Map<String, dynamic> json) =>
      _$EntityDeltasFromJson(json);

  Map<String, dynamic> toJson() => _$EntityDeltasToJson(this);
}

/// Payload containing all entity deltas
@JsonSerializable()
class DeltaPayload {
  final EntityDeltas classes;
  final EntityDeltas enrollments;
  final EntityDeltas assessments;
  final EntityDeltas questions;

  @JsonKey(name: 'assessment_submissions')
  final EntityDeltas assessmentSubmissions;

  final EntityDeltas assignments;

  @JsonKey(name: 'assignment_submissions')
  final EntityDeltas assignmentSubmissions;

  @JsonKey(name: 'learning_materials')
  final EntityDeltas learningMaterials;

  @JsonKey(name: 'grade_configs')
  final EntityDeltas gradeConfigs;

  @JsonKey(name: 'grade_items')
  final EntityDeltas gradeItems;

  @JsonKey(name: 'grade_scores')
  final EntityDeltas gradeScores;

  @JsonKey(name: 'period_grades')
  final EntityDeltas periodGrades;

  @JsonKey(name: 'table_of_specifications')
  final EntityDeltas tableOfSpecifications;

  @JsonKey(name: 'tos_competencies')
  final EntityDeltas tosCompetencies;

  DeltaPayload({
    required this.classes,
    required this.enrollments,
    required this.assessments,
    required this.questions,
    required this.assessmentSubmissions,
    required this.assignments,
    required this.assignmentSubmissions,
    required this.learningMaterials,
    required this.gradeConfigs,
    required this.gradeItems,
    required this.gradeScores,
    required this.periodGrades,
    required this.tableOfSpecifications,
    required this.tosCompetencies,
  });

  factory DeltaPayload.fromJson(Map<String, dynamic> json) =>
      _$DeltaPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$DeltaPayloadToJson(this);
}

/// Response from /api/sync/deltas endpoint
/// Can be either deltas or data_expired status
@JsonSerializable()
class DeltaSyncResponseModel {
  @JsonKey(name: 'sync_token')
  final String? syncToken;

  @JsonKey(name: 'server_time')
  final String? serverTime;

  final DeltaPayload? deltas;

  /// If true, this is a data_expired response
  final String? status;
  final String? message;

  DeltaSyncResponseModel({
    this.syncToken,
    this.serverTime,
    this.deltas,
    this.status,
    this.message,
  });

  factory DeltaSyncResponseModel.fromJson(Map<String, dynamic> json) =>
      _$DeltaSyncResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeltaSyncResponseModelToJson(this);

  /// Check if this is a data_expired response
  bool get isExpired => status == 'data_expired';
}
