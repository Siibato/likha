import 'package:likha/domain/auth/data/models/user_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';

class ClassDetailModel extends ClassDetail {
  const ClassDetailModel({
    required super.id,
    required super.title,
    super.description,
    required super.teacherId,
    required super.isArchived,
    required super.students,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClassDetailModel.fromJson(Map<String, dynamic> json) {
    return ClassDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as String,
      isArchived: json['is_archived'] as bool,
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.id,
    required super.student,
    required super.enrolledAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as String,
      student: UserModel.fromJson(json['student'] as Map<String, dynamic>),
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
    );
  }
}
