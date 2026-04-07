import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';

class ClassDetailModel extends ClassDetail {
  const ClassDetailModel({
    required super.id,
    required super.title,
    super.description,
    required super.teacherId,
    required super.isArchived,
    super.isAdvisory,
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
      isAdvisory: json['is_advisory'] as bool? ?? false,
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ParticipantModel extends Participant {
  const ParticipantModel({
    required super.id,
    required super.student,
    required super.joinedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    // Accept both new field name (joined_at) and old field name (enrolled_at) for backward compat
    final joinedAtStr = (json['joined_at'] ?? json['enrolled_at']) as String?;
    if (joinedAtStr == null) {
      throw ArgumentError('Missing joined_at or enrolled_at field');
    }

    return ParticipantModel(
      id: json['id'] as String,
      student: UserModel.fromJson(json['student'] as Map<String, dynamic>),
      joinedAt: DateTime.parse(joinedAtStr),
    );
  }
}
