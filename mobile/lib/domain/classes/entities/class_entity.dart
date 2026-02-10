import 'package:equatable/equatable.dart';

class ClassEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final bool isArchived;
  final int studentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassEntity({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.isArchived,
    required this.studentCount,
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
    studentCount,
    createdAt,
    updatedAt,
  ];
}
