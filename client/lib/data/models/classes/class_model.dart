import 'package:likha/domain/classes/entities/class_entity.dart';

class ClassModel extends ClassEntity {
  final DateTime? deletedAt;

  const ClassModel({
    required super.id,
    required super.title,
    super.description,
    required super.teacherId,
    required super.teacherUsername,
    required super.teacherFullName,
    required super.isArchived,
    super.isAdvisory,
    required super.studentCount,
    super.gradingPeriodType,
    required super.createdAt,
    required super.updatedAt,
    super.cachedAt,
    super.needsSync = false,
    this.deletedAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as String,
      teacherUsername: json['teacher_username'] as String,
      teacherFullName: json['teacher_full_name'] as String,
      isArchived: json['is_archived'] as bool,
      isAdvisory: json['is_advisory'] as bool? ?? false,
      studentCount: json['student_count'] as int? ?? 0,
      gradingPeriodType: json['grading_period_type'] as String? ?? 'quarter',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      teacherId: map['teacher_id'] as String? ?? '',
      teacherUsername: map['teacher_username'] as String? ?? '',
      teacherFullName: map['teacher_full_name'] as String? ?? '',
      isArchived: (map['is_archived'] as int?) == 1,
      isAdvisory: (map['is_advisory'] as int?) == 1,
      studentCount: map['student_count'] as int? ?? 0,
      gradingPeriodType: map['grading_period_type'] as String? ?? 'quarter',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teacher_id': teacherId,
      'teacher_username': teacherUsername,
      'teacher_full_name': teacherFullName,
      'is_archived': isArchived ? 1 : 0,
      'is_advisory': isAdvisory ? 1 : 0,
      'student_count': studentCount,
      'grading_period_type': gradingPeriodType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
