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
  final int orderIndex;
  final int submissionCount;
  final int gradedCount;
  final String? submissionStatus; // Student's own submission status
  final String? submissionId; // Student's own submission ID
  final int? score; // Student's own score
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cachedAt;
  final bool needsSync;

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
    required this.orderIndex,
    required this.submissionCount,
    required this.gradedCount,
    this.submissionStatus,
    this.submissionId,
    this.score,
    required this.createdAt,
    required this.updatedAt,
    this.cachedAt,
    this.needsSync = false,
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
        orderIndex,
        submissionCount,
        gradedCount,
        submissionStatus,
        submissionId,
        score,
        createdAt,
        updatedAt,
        cachedAt,
        needsSync,
      ];
}
