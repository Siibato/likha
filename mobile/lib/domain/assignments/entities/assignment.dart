import 'package:equatable/equatable.dart';

class Assignment extends Equatable {
  final String id;
  final String classId;
  final String title;
  final String instructions;
  final int totalPoints;
  final bool allowsTextSubmission;
  final bool allowsFileSubmission;
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
  final int? gradingPeriodNumber;
  final String? component;
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
    required this.allowsTextSubmission,
    required this.allowsFileSubmission,
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
    this.gradingPeriodNumber,
    this.component,
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
        allowsTextSubmission,
        allowsFileSubmission,
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
        gradingPeriodNumber,
        component,
        createdAt,
        updatedAt,
        cachedAt,
        needsSync,
      ];

  Assignment copyWith({
    String? id,
    String? classId,
    String? title,
    String? instructions,
    int? totalPoints,
    bool? allowsTextSubmission,
    bool? allowsFileSubmission,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    DateTime? dueAt,
    bool? isPublished,
    int? orderIndex,
    int? submissionCount,
    int? gradedCount,
    String? submissionStatus,
    String? submissionId,
    int? score,
    int? gradingPeriodNumber,
    String? component,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    bool? needsSync,
  }) {
    return Assignment(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      totalPoints: totalPoints ?? this.totalPoints,
      allowsTextSubmission: allowsTextSubmission ?? this.allowsTextSubmission,
      allowsFileSubmission: allowsFileSubmission ?? this.allowsFileSubmission,
      allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb ?? this.maxFileSizeMb,
      dueAt: dueAt ?? this.dueAt,
      isPublished: isPublished ?? this.isPublished,
      orderIndex: orderIndex ?? this.orderIndex,
      submissionCount: submissionCount ?? this.submissionCount,
      gradedCount: gradedCount ?? this.gradedCount,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionId: submissionId ?? this.submissionId,
      score: score ?? this.score,
      gradingPeriodNumber: gradingPeriodNumber ?? this.gradingPeriodNumber,
      component: component ?? this.component,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }
}
