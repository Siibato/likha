import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

enum TaskStatus { pending, submitted, graded, missing }

enum TaskType { assignment, assessment }

class TaskItem {
  final String id;
  final String classId;
  final String className;
  final String title;
  final DateTime dueAt;
  final int totalPoints;
  final TaskStatus status;
  final int? score;
  final TaskType type;
  final DateTime? openAt;
  final DateTime? closeAt;
  final Assignment? assignment;
  final Assessment? assessment;

  TaskItem({
    required this.id,
    required this.classId,
    required this.className,
    required this.title,
    required this.dueAt,
    required this.totalPoints,
    required this.status,
    this.score,
    this.type = TaskType.assignment,
    this.openAt,
    this.closeAt,
    this.assignment,
    this.assessment,
  });

  // Factory to convert Assignment to TaskItem
  factory TaskItem.fromAssignment(Assignment assignment, String className) {
    final status = _deriveStatus(assignment.submissionStatus, assignment.dueAt);
    return TaskItem(
      type: TaskType.assignment,
      id: assignment.id,
      classId: assignment.classId,
      className: className,
      title: assignment.title,
      dueAt: assignment.dueAt,
      totalPoints: assignment.totalPoints,
      status: status,
      score: assignment.score,
      assignment: assignment,
    );
  }

  // Factory to convert Assessment to TaskItem
  factory TaskItem.fromAssessment(Assessment assessment, String className) {
    final status = _deriveAssessmentStatus(assessment);
    return TaskItem(
      type: TaskType.assessment,
      id: assessment.id,
      classId: assessment.classId,
      className: className,
      title: assessment.title,
      dueAt: assessment.closeAt,
      openAt: assessment.openAt,
      closeAt: assessment.closeAt,
      totalPoints: assessment.totalPoints,
      status: status,
      score: null,
      assessment: assessment,
    );
  }

  // Derive status from submission status and due date (for assignments)
  static TaskStatus _deriveStatus(String? submissionStatus, DateTime dueAt) {
    if (submissionStatus == 'graded' || submissionStatus == 'returned') {
      return TaskStatus.graded;
    } else if (submissionStatus == 'submitted') {
      return TaskStatus.submitted;
    } else {
      final now = sl<ServerClockService>().now();
      if (dueAt.isBefore(now)) {
        return TaskStatus.missing;
      } else {
        return TaskStatus.pending;
      }
    }
  }

  // Derive status from assessment (for assessments)
  static TaskStatus _deriveAssessmentStatus(Assessment assessment) {
    final now = sl<ServerClockService>().now();
    if (assessment.isSubmitted == true) return TaskStatus.submitted;
    if (now.isAfter(assessment.closeAt)) return TaskStatus.missing;
    return TaskStatus.pending;
  }
}

class StudentTasksState {
  final bool isLoading;
  final List<TaskItem> tasks;
  final String? error;

  StudentTasksState({
    required this.isLoading,
    required this.tasks,
    this.error,
  });

  StudentTasksState.initial()
      : isLoading = false,
        tasks = [],
        error = null;

  StudentTasksState copyWith({
    bool? isLoading,
    List<TaskItem>? tasks,
    String? error,
  }) {
    return StudentTasksState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      error: error ?? this.error,
    );
  }
}

class StudentTasksNotifier extends StateNotifier<StudentTasksState> {
  StudentTasksNotifier(this._ref) : super(StudentTasksState.initial());

  final Ref _ref;

  Future<void> loadAllTasks({bool skipBackgroundRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get enrolled classes from classProvider
      final classState = _ref.read(classProvider);
      final enrolledClasses = classState.classes;

      // Map classId → className for quick lookup
      final classNameMap = {
        for (final cls in enrolledClasses) cls.id: cls.title,
      };

      final allTasks = <TaskItem>[];
      final getAssignmentsUseCase = sl<GetAssignments>();
      final getAssessmentsUseCase = sl<GetAssessments>();

      // For each class, load assignments
      for (final cls in enrolledClasses) {
        try {
          final result = await getAssignmentsUseCase(
            cls.id,
            publishedOnly: true,
            skipBackgroundRefresh: skipBackgroundRefresh,
          );

          result.fold(
            (failure) {
              // Skip failed classes, continue with others
            },
            (assignments) {
              // Convert to TaskItem
              final tasks = assignments
                  .map((a) => TaskItem.fromAssignment(a, classNameMap[cls.id] ?? 'Unknown'))
                  .toList();
              allTasks.addAll(tasks);
            },
          );
        } catch (_) {
          // Skip if error loading assignments for this class
        }
      }

      // For each class, load assessments
      for (final cls in enrolledClasses) {
        try {
          final result = await getAssessmentsUseCase(
            cls.id,
            publishedOnly: true,
            skipBackgroundRefresh: skipBackgroundRefresh,
          );

          result.fold(
            (failure) {
              // Skip failed classes, continue with others
            },
            (assessments) {
              // Convert to TaskItem
              final tasks = assessments
                  .map((a) => TaskItem.fromAssessment(a, classNameMap[cls.id] ?? 'Unknown'))
                  .toList();
              allTasks.addAll(tasks);
            },
          );
        } catch (_) {
          // Skip if error loading assessments for this class
        }
      }

      // Sort by dueAt ascending (nearest due dates first)
      allTasks.sort((a, b) => a.dueAt.compareTo(b.dueAt));

      state = state.copyWith(isLoading: false, tasks: allTasks);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }
}

final studentTasksProvider =
    StateNotifierProvider<StudentTasksNotifier, StudentTasksState>((ref) {
  final notifier = StudentTasksNotifier(ref);
  ref.listen<SyncState>(syncProvider, (previous, next) {
    final assignmentsTrigger = !(previous?.assignmentsReady ?? false) && next.assignmentsReady;
    final assessmentsTrigger = !(previous?.assessmentsReady ?? false) && next.assessmentsReady;
    if (assignmentsTrigger || assessmentsTrigger) {
      notifier.loadAllTasks(skipBackgroundRefresh: true);
    }
  });
  return notifier;
});
