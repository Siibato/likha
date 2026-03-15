import 'package:equatable/equatable.dart';
import 'package:likha/domain/auth/entities/user.dart';

class ClassDetail extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final bool isArchived;
  final List<Enrollment> students;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassDetail({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.isArchived,
    required this.students,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    teacherId,
    isArchived,
    students,
    createdAt,
    updatedAt,
  ];
}

class Enrollment extends Equatable {
  final String id;
  final User student;
  final DateTime joinedAt;

  const Enrollment({
    required this.id,
    required this.student,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, student, joinedAt];
}
