import 'package:equatable/equatable.dart';
import 'package:likha/domain/auth/entities/user.dart';

class ClassDetail extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final bool isArchived;
  final bool isAdvisory;
  final List<Participant> students;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassDetail({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.isArchived,
    this.isAdvisory = false,
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
    isAdvisory,
    students,
    createdAt,
    updatedAt,
  ];
}

class Participant extends Equatable {
  final String id;
  final User student;
  final DateTime joinedAt;

  const Participant({
    required this.id,
    required this.student,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, student, joinedAt];
}
