import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/class_provider.dart';

enum TaskStatus { pending, submitted, graded, missing }

class TaskItem {
  final String id;
  final String classId;
  final String className;
  final String title;
  final DateTime dueAt;
  final int totalPoints;
  final TaskStatus status;
  final int? score;

  TaskItem({
    required this.id,
    required this.classId,
    required this.className,
    required this.title,
    required this.dueAt,
    required this.totalPoints,
    required this.status,
    this.score,
  });

  // Factory to convert Assignment to TaskItem
  factory TaskItem.fromAssignment(Assignment assignment, String className) {
    final status = _deriveStatus(assignment.submissionStatus, assignment.dueAt);
    return TaskItem(
      id: assignment.id,
      classId: assignment.classId,
      className: className,
      title: assignment.title,
      dueAt: assignment.dueAt,
      totalPoints: assignment.totalPoints,
      status: status,
      score: assignment.score,
    );
  }

  // Derive status from submission status and due date
  static TaskStatus _deriveStatus(String? submissionStatus, DateTime dueAt) {
    if (submissionStatus == 'graded' || submissionStatus == 'returned') {
      return TaskStatus.graded;
    } else if (submissionStatus == 'submitted') {
      return TaskStatus.submitted;
    } else {
      final now = DateTime.now();
      if (dueAt.isBefore(now)) {
        return TaskStatus.missing;
      } else {
        return TaskStatus.pending;
      }
    }
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

  Future<void> loadAllTasks() async {
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

      // For each class, load assignments
      for (final cls in enrolledClasses) {
        try {
          final result = await getAssignmentsUseCase(cls.id);

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

      // Sort by dueAt ascending (nearest due dates first)
      allTasks.sort((a, b) => a.dueAt.compareTo(b.dueAt));

      state = state.copyWith(isLoading: false, tasks: allTasks);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final studentTasksProvider =
    StateNotifierProvider<StudentTasksNotifier, StudentTasksState>((ref) {
  return StudentTasksNotifier(ref);
});
