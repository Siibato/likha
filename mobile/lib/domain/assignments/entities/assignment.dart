import 'package:equatable/equatable.dart';

class Assignment extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String instructions;
  final int totalPoints;
  final String submissionType;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final DateTime dueAt;
  final bool isPublished;
  final int submissionCount;
  final int gradedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Assignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.instructions,
    required this.totalPoints,
    required this.submissionType,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    required this.dueAt,
    required this.isPublished,
    required this.submissionCount,
    required this.gradedCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        classId,
        title,
        instructions,
        totalPoints,
        submissionType,
        allowedFileTypes,
        maxFileSizeMb,
        dueAt,
        isPublished,
        submissionCount,
        gradedCount,
        createdAt,
        updatedAt,
      ];
}
