// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'full_sync_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncPlanModel _$SyncPlanModelFromJson(Map<String, dynamic> json) =>
    SyncPlanModel(
      needsEntityBatches: json['needs_entity_batches'] as bool,
      totalClasses: (json['total_classes'] as num).toInt(),
    );

Map<String, dynamic> _$SyncPlanModelToJson(SyncPlanModel instance) =>
    <String, dynamic>{
      'needs_entity_batches': instance.needsEntityBatches,
      'total_classes': instance.totalClasses,
    };

FullSyncResponseModel _$FullSyncResponseModelFromJson(
  Map<String, dynamic> json,
) => FullSyncResponseModel(
  syncToken: json['sync_token'] as String,
  serverTime: json['server_time'] as String,
  classes: (json['classes'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  enrollments: (json['enrollments'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assessments: (json['assessments'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  questions: (json['questions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assessmentSubmissions: (json['assessment_submissions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assignments: (json['assignments'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assignmentSubmissions: (json['assignment_submissions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  learningMaterials: (json['learning_materials'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  materialFiles:
      (json['material_files'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  submissionFiles:
      (json['submission_files'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  assessmentStatistics:
      (json['assessment_statistics'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  studentResults:
      (json['student_results'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  gradeConfigs:
      (json['grade_configs'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  gradeItems:
      (json['grade_items'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  gradeScores:
      (json['grade_scores'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  periodGrades:
      (json['period_grades'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  tableOfSpecifications:
      (json['table_of_specifications'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  tosCompetencies:
      (json['tos_competencies'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  activityLogs:
      (json['activity_logs'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  user: json['user'] as Map<String, dynamic>?,
  enrolledStudents: (json['enrolled_students'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  syncPlan: json['sync_plan'] == null
      ? null
      : SyncPlanModel.fromJson(json['sync_plan'] as Map<String, dynamic>),
  schoolDetails: json['school_details'] as Map<String, dynamic>?,
  learnerDetails:
      (json['learner_details'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  attendanceRecords:
      (json['attendance_records'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  coreValuesRecords:
      (json['core_values_records'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  studentSchoolHistory:
      (json['student_school_history'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  previousSchoolSubjects:
      (json['previous_school_subjects'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
  previousSchoolAttendance:
      (json['previous_school_attendance'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      [],
);

Map<String, dynamic> _$FullSyncResponseModelToJson(
  FullSyncResponseModel instance,
) => <String, dynamic>{
  'sync_token': instance.syncToken,
  'server_time': instance.serverTime,
  'classes': instance.classes,
  'enrollments': instance.enrollments,
  'assessments': instance.assessments,
  'questions': instance.questions,
  'assessment_submissions': instance.assessmentSubmissions,
  'assignments': instance.assignments,
  'assignment_submissions': instance.assignmentSubmissions,
  'learning_materials': instance.learningMaterials,
  'material_files': instance.materialFiles,
  'submission_files': instance.submissionFiles,
  'assessment_statistics': instance.assessmentStatistics,
  'student_results': instance.studentResults,
  'grade_configs': instance.gradeConfigs,
  'grade_items': instance.gradeItems,
  'grade_scores': instance.gradeScores,
  'period_grades': instance.periodGrades,
  'table_of_specifications': instance.tableOfSpecifications,
  'tos_competencies': instance.tosCompetencies,
  'activity_logs': instance.activityLogs,
  'user': instance.user,
  'enrolled_students': instance.enrolledStudents,
  'sync_plan': instance.syncPlan,
  'school_details': instance.schoolDetails,
  'learner_details': instance.learnerDetails,
  'attendance_records': instance.attendanceRecords,
  'core_values_records': instance.coreValuesRecords,
  'student_school_history': instance.studentSchoolHistory,
  'previous_school_subjects': instance.previousSchoolSubjects,
  'previous_school_attendance': instance.previousSchoolAttendance,
};
