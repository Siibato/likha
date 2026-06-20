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

  @JsonKey(name: 'term_grades')
  final EntityDeltas termGrades;

  @JsonKey(name: 'table_of_specifications')
  final EntityDeltas tableOfSpecifications;

  @JsonKey(name: 'tos_competencies')
  final EntityDeltas tosCompetencies;

  @JsonKey(name: 'activity_logs')
  final EntityDeltas activityLogs;

  @JsonKey(name: 'school_details')
  final EntityDeltas schoolDetails;

  @JsonKey(name: 'learner_details')
  final EntityDeltas learnerDetails;

  @JsonKey(name: 'attendance_records')
  final EntityDeltas attendanceRecords;

  @JsonKey(name: 'core_values_records')
  final EntityDeltas coreValuesRecords;

  @JsonKey(name: 'student_school_history')
  final EntityDeltas studentSchoolHistory;

  @JsonKey(name: 'previous_school_subjects')
  final EntityDeltas previousSchoolSubjects;

  @JsonKey(name: 'previous_school_term_grades')
  final EntityDeltas previousSchoolTermGrades;

  @JsonKey(name: 'previous_school_attendance')
  final EntityDeltas previousSchoolAttendance;

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
    required this.termGrades,
    required this.tableOfSpecifications,
    required this.tosCompetencies,
    required this.activityLogs,
    required this.schoolDetails,
    required this.learnerDetails,
    required this.attendanceRecords,
    required this.coreValuesRecords,
    required this.studentSchoolHistory,
    required this.previousSchoolSubjects,
    required this.previousSchoolTermGrades,
    required this.previousSchoolAttendance,
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
