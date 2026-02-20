import 'package:likha/domain/classes/entities/class_entity.dart';

class ClassModel extends ClassEntity {
  const ClassModel({
    required super.id,
    required super.title,
    super.description,
    required super.teacherId,
    required super.teacherUsername,
    required super.teacherFullName,
    required super.isArchived,
    required super.studentCount,
    required super.createdAt,
    required super.updatedAt,
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
      studentCount: json['student_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      teacherId: map['teacher_id'] as String,
      teacherUsername: map['teacher_username'] as String,
      teacherFullName: map['teacher_full_name'] as String,
      isArchived: (map['is_archived'] as int?) == 1,
      studentCount: map['student_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
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
      'student_count': studentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
