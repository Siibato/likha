import 'package:json_annotation/json_annotation.dart';

part 'full_sync_response_model.g.dart';

@JsonSerializable()
class SyncPlanModel {
  @JsonKey(name: 'needs_entity_batches')
  final bool needsEntityBatches;

  @JsonKey(name: 'total_classes')
  final int totalClasses;

  SyncPlanModel({
    required this.needsEntityBatches,
    required this.totalClasses,
  });

  factory SyncPlanModel.fromJson(Map<String, dynamic> json) =>
      _$SyncPlanModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncPlanModelToJson(this);
}

@JsonSerializable()
class FullSyncResponseModel {
  @JsonKey(name: 'sync_token')
  final String syncToken;

  @JsonKey(name: 'server_time')
  final String serverTime;

  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> enrollments;
  final List<Map<String, dynamic>> assessments;
  final List<Map<String, dynamic>> questions;

  @JsonKey(name: 'assessment_submissions')
  final List<Map<String, dynamic>> assessmentSubmissions;

  final List<Map<String, dynamic>> assignments;

  @JsonKey(name: 'assignment_submissions')
  final List<Map<String, dynamic>> assignmentSubmissions;

  @JsonKey(name: 'learning_materials')
  final List<Map<String, dynamic>> learningMaterials;

  @JsonKey(name: 'material_files', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> materialFiles;

  @JsonKey(name: 'submission_files', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> submissionFiles;

  @JsonKey(name: 'assessment_statistics', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> assessmentStatistics;

  @JsonKey(name: 'student_results', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> studentResults;

  @JsonKey(name: 'grade_configs', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> gradeConfigs;

  @JsonKey(name: 'grade_items', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> gradeItems;

  @JsonKey(name: 'grade_scores', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> gradeScores;

  @JsonKey(name: 'term_grades', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> termGrades;

  @JsonKey(name: 'table_of_specifications', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> tableOfSpecifications;

  @JsonKey(name: 'tos_competencies', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> tosCompetencies;

  @JsonKey(name: 'activity_logs', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> activityLogs;

  final Map<String, dynamic>? user;

  @JsonKey(name: 'enrolled_students')
  final List<Map<String, dynamic>>? enrolledStudents;

  @JsonKey(name: 'sync_plan')
  final SyncPlanModel? syncPlan;

  @JsonKey(name: 'school_details')
  final Map<String, dynamic>? schoolDetails;

  @JsonKey(name: 'learner_details', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> learnerDetails;

  @JsonKey(name: 'teacher_details', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> teacherDetails;

  @JsonKey(name: 'attendance_records', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> attendanceRecords;

  @JsonKey(name: 'core_values_records', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> coreValuesRecords;

  @JsonKey(name: 'student_school_history', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> studentSchoolHistory;

  @JsonKey(name: 'previous_school_subjects', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> previousSchoolSubjects;

  @JsonKey(name: 'previous_school_term_grades', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> previousSchoolTermGrades;

  @JsonKey(name: 'previous_school_attendance', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> previousSchoolAttendance;

  FullSyncResponseModel({
    required this.syncToken,
    required this.serverTime,
    required this.classes,
    required this.enrollments,
    required this.assessments,
    required this.questions,
    required this.assessmentSubmissions,
    required this.assignments,
    required this.assignmentSubmissions,
    required this.learningMaterials,
    this.materialFiles = const [],
    this.submissionFiles = const [],
    this.assessmentStatistics = const [],
    this.studentResults = const [],
    this.gradeConfigs = const [],
    this.gradeItems = const [],
    this.gradeScores = const [],
    this.termGrades = const [],
    this.tableOfSpecifications = const [],
    this.tosCompetencies = const [],
    this.activityLogs = const [],
    this.user,
    this.enrolledStudents,
    this.syncPlan,
    this.schoolDetails,
    this.learnerDetails = const [],
    this.teacherDetails = const [],
    this.attendanceRecords = const [],
    this.coreValuesRecords = const [],
    this.studentSchoolHistory = const [],
    this.previousSchoolSubjects = const [],
    this.previousSchoolTermGrades = const [],
    this.previousSchoolAttendance = const [],
  });

  factory FullSyncResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FullSyncResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$FullSyncResponseModelToJson(this);
}
