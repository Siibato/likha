import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/class_provider.dart';

// Status string constants for assignment submission status
const String kStatusGraded = 'graded';
const String kStatusReturned = 'returned';

/// Per-class grade data with transmuted score
class ClassGradeData {
  final String classId;
  final String className;
  final int reportGrade; // transmuted: 60–100
  final int gradedCount;
  final int totalCount;
  final List<Assignment> assignments; // full list for detail page

  ClassGradeData({
    required this.classId,
    required this.className,
    required this.reportGrade,
    required this.gradedCount,
    required this.totalCount,
    required this.assignments,
  });
}

class StudentClassGradesState {
  final bool isLoading;
  final List<ClassGradeData> classGrades; // sorted by className
  final String? error;

  StudentClassGradesState({
    required this.isLoading,
    required this.classGrades,
    this.error,
  });

  StudentClassGradesState.initial()
      : isLoading = false,
        classGrades = [],
        error = null;

  StudentClassGradesState copyWith({
    bool? isLoading,
    List<ClassGradeData>? classGrades,
    String? error,
    bool clearError = false,
  }) {
    return StudentClassGradesState(
      isLoading: isLoading ?? this.isLoading,
      classGrades: classGrades ?? this.classGrades,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StudentClassGradesNotifier extends StateNotifier<StudentClassGradesState> {
  StudentClassGradesNotifier(this._ref)
      : super(StudentClassGradesState.initial()) {
    _setupEventSubscriptions();
  }

  final Ref _ref;
  late StreamSubscription<String?> _assignmentsChangedSub;

  void _setupEventSubscriptions() {
    // Reload grades when assignments change in any class
    _assignmentsChangedSub = sl<DataEventBus>().onAssignmentsChanged.listen((_) {
      if (state.classGrades.isNotEmpty) {
        loadAllClassGrades();
      }
    });
  }

  Future<void> loadAllClassGrades() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get enrolled classes from classProvider
      final classState = _ref.read(classProvider);
      final enrolledClasses = classState.classes;

      if (enrolledClasses.isEmpty) {
        state = state.copyWith(isLoading: false, classGrades: []);
        return;
      }

      final allGrades = <ClassGradeData>[];
      final getAssignmentsUseCase = sl<GetAssignments>();

      // For each class, load assignments and compute grade
      for (final cls in enrolledClasses) {
        try {
          final result = await getAssignmentsUseCase(cls.id);

          result.fold(
            (failure) {
              // Skip failed classes, continue with others
            },
            (assignments) {
              // Compute raw score and transmute
              final rawScore =
                  TransmutationUtil.computeRawScore(assignments);
              final reportGrade = TransmutationUtil.transmute(rawScore);
              final gradedCount = assignments
                  .where((a) =>
                      a.submissionStatus == kStatusGraded ||
                      a.submissionStatus == kStatusReturned)
                  .length;

              allGrades.add(ClassGradeData(
                classId: cls.id,
                className: cls.title,
                reportGrade: reportGrade,
                gradedCount: gradedCount,
                totalCount: assignments.length,
                assignments: assignments,
              ));
            },
          );
        } catch (_) {
          // Skip if error loading assignments for this class
        }
      }

      // Sort by className alphabetically
      allGrades.sort((a, b) => a.className.compareTo(b.className));

      state = state.copyWith(isLoading: false, classGrades: allGrades);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _assignmentsChangedSub.cancel();
    super.dispose();
  }
}

final studentClassGradesProvider = StateNotifierProvider<
    StudentClassGradesNotifier,
    StudentClassGradesState>((ref) {
  return StudentClassGradesNotifier(ref);
});
