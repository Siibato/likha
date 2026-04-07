import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/entities/quarterly_grade.dart';
import 'package:likha/domain/grading/usecases/get_my_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/class_provider.dart';

/// Per-class grade data derived from the DepEd quarterly grading system.
class ClassGradeData {
  final String classId;
  final String className;
  final List<QuarterlyGrade> quarterlyGrades;
  final int? latestGrade; // transmuted grade from most recent quarter
  final String latestDescriptor;
  final int? latestQuarter; // which quarter the latest grade is from

  ClassGradeData({
    required this.classId,
    required this.className,
    required this.quarterlyGrades,
    this.latestGrade,
    this.latestDescriptor = '--',
    this.latestQuarter,
  });
}

class StudentClassGradesState {
  final bool isLoading;
  final List<ClassGradeData> classGrades;
  final String? error;
  final double? generalAverage;
  final String? generalAverageDescriptor;

  StudentClassGradesState({
    required this.isLoading,
    required this.classGrades,
    this.error,
    this.generalAverage,
    this.generalAverageDescriptor,
  });

  StudentClassGradesState.initial()
      : isLoading = false,
        classGrades = [],
        error = null,
        generalAverage = null,
        generalAverageDescriptor = null;

  StudentClassGradesState copyWith({
    bool? isLoading,
    List<ClassGradeData>? classGrades,
    String? error,
    bool clearError = false,
    double? generalAverage,
    String? generalAverageDescriptor,
    bool clearGeneralAverage = false,
  }) {
    return StudentClassGradesState(
      isLoading: isLoading ?? this.isLoading,
      classGrades: classGrades ?? this.classGrades,
      error: clearError ? null : (error ?? this.error),
      generalAverage:
          clearGeneralAverage ? null : (generalAverage ?? this.generalAverage),
      generalAverageDescriptor: clearGeneralAverage
          ? null
          : (generalAverageDescriptor ?? this.generalAverageDescriptor),
    );
  }
}

class StudentClassGradesNotifier
    extends StateNotifier<StudentClassGradesState> {
  StudentClassGradesNotifier(this._ref)
      : super(StudentClassGradesState.initial()) {
    _setupEventSubscriptions();
  }

  final Ref _ref;
  late StreamSubscription<void> _classesChangedSub;

  void _setupEventSubscriptions() {
    // Reload grades when classes change (enrollment updates, sync, etc.)
    _classesChangedSub = sl<DataEventBus>().onClassesChanged.listen((_) {
      if (state.classGrades.isNotEmpty) {
        loadAllClassGrades();
      }
    });
  }

  Future<void> loadAllClassGrades() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final classState = _ref.read(classProvider);
      final enrolledClasses = classState.classes;

      if (enrolledClasses.isEmpty) {
        state = state.copyWith(isLoading: false, classGrades: []);
        return;
      }

      final allGrades = <ClassGradeData>[];
      final getMyGrades = sl<GetMyGrades>();

      for (final cls in enrolledClasses) {
        try {
          final result = await getMyGrades(cls.id);

          result.fold(
            (failure) {
              // Skip failed classes, continue with others
            },
            (quarterlyGrades) {
              // Find the most recent quarter with a transmuted grade
              QuarterlyGrade? latest;
              for (final qg in quarterlyGrades) {
                if (qg.transmutedGrade != null) {
                  if (latest == null || qg.quarter > latest.quarter) {
                    latest = qg;
                  }
                }
              }

              allGrades.add(ClassGradeData(
                classId: cls.id,
                className: cls.title,
                quarterlyGrades: quarterlyGrades,
                latestGrade: latest?.transmutedGrade,
                latestDescriptor: latest != null
                    ? TransmutationUtil.getDescriptor(
                        latest.transmutedGrade ?? 0)
                    : '--',
                latestQuarter: latest?.quarter,
              ));
            },
          );
        } catch (_) {
          // Skip if error loading grades for this class
        }
      }

      // Sort by className alphabetically
      allGrades.sort((a, b) => a.className.compareTo(b.className));

      // Compute general average across all classes
      double? generalAverage;
      String? generalAverageDescriptor;

      final classAverages = <double>[];
      for (final cg in allGrades) {
        final withGrades = cg.quarterlyGrades
            .where((qg) => qg.transmutedGrade != null)
            .toList();
        if (withGrades.isNotEmpty) {
          final sum = withGrades.fold<int>(
              0, (acc, qg) => acc + qg.transmutedGrade!);
          classAverages.add(sum / withGrades.length);
        }
      }

      if (classAverages.isNotEmpty) {
        final total =
            classAverages.fold<double>(0, (acc, avg) => acc + avg);
        generalAverage =
            double.parse((total / classAverages.length).toStringAsFixed(1));
        generalAverageDescriptor =
            TransmutationUtil.getDescriptor(generalAverage.round());
      }

      state = state.copyWith(
        isLoading: false,
        classGrades: allGrades,
        generalAverage: generalAverage,
        generalAverageDescriptor: generalAverageDescriptor,
        clearGeneralAverage: generalAverage == null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  void dispose() {
    _classesChangedSub.cancel();
    super.dispose();
  }
}

final studentClassGradesProvider = StateNotifierProvider<
    StudentClassGradesNotifier, StudentClassGradesState>((ref) {
  return StudentClassGradesNotifier(ref);
});
