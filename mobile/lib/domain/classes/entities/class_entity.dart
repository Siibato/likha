import 'package:equatable/equatable.dart';

class ClassEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final String teacherUsername;
  final String teacherFullName;
  final bool isArchived;
  final int studentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cachedAt;
  final bool needsSync;

  const ClassEntity({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.teacherUsername,
    required this.teacherFullName,
    required this.isArchived,
    required this.studentCount,
    required this.createdAt,
    required this.updatedAt,
    this.cachedAt,
    this.needsSync = false,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    teacherId,
    teacherUsername,
    teacherFullName,
    isArchived,
    studentCount,
    createdAt,
    updatedAt,
    cachedAt,
    needsSync,
  ];
}
