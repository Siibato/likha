import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_student_submission.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/get_student_assignment_submission.dart';
import 'package:likha/injection_container.dart';

class AssessmentWithStatus extends Equatable {
  final Assessment assessment;
  final SubmissionSummary? submission;  // null = not attempted

  const AssessmentWithStatus({
    required this.assessment,
    this.submission,
  });

  @override
  List<Object?> get props => [assessment, submission];
}

class AssignmentWithStatus extends Equatable {
  final Assignment assignment;
  final StudentAssignmentStatus? status;  // null = not submitted

  const AssignmentWithStatus({
    required this.assignment,
    this.status,
  });

  @override
  List<Object?> get props => [assignment, status];
}

class TeacherStudentDetailState extends Equatable {
  final List<AssessmentWithStatus> assessments;
  final List<AssignmentWithStatus> assignments;
  final bool isLoading;
  final String? error;

  const TeacherStudentDetailState({
    this.assessments = const [],
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  TeacherStudentDetailState copyWith({
    List<AssessmentWithStatus>? assessments,
    List<AssignmentWithStatus>? assignments,
    bool? isLoading,
    String? error,
  }) {
    return TeacherStudentDetailState(
      assessments: assessments ?? this.assessments,
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [assessments, assignments, isLoading, error];
}

class TeacherStudentDetailNotifier extends StateNotifier<TeacherStudentDetailState> {
  final String classId;
  final String studentId;
  late StreamSubscription<String?> _assessmentSub;
  late StreamSubscription<String?> _assignmentSub;

  TeacherStudentDetailNotifier(this.classId, this.studentId)
      : super(const TeacherStudentDetailState(isLoading: true)) {
    // Subscribe to DataEventBus for auto-refresh
    _assessmentSub = sl<DataEventBus>().onAssessmentsChanged.listen((id) {
      if (id == classId) _reloadFromCache();
    });
    _assignmentSub = sl<DataEventBus>().onAssignmentsChanged.listen((id) {
      if (id == classId) _reloadFromCache();
    });
    _init();
  }

  @override
  void dispose() {
    _assessmentSub.cancel();
    _assignmentSub.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Phase 1: Load from cache (returns immediately)
    // skipBackgroundRefresh: false → existing background list refresh fires automatically
    await _reloadFromCache(skipBackgroundRefresh: false);

    // Phase 2: Background fetch student submission statuses
    _backgroundFetchSubmissionStatuses();
  }

  Future<void> _reloadFromCache({bool skipBackgroundRefresh = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load both lists in parallel
      final results = await Future.wait([
        sl<GetAssessments>()(classId, publishedOnly: true, skipBackgroundRefresh: skipBackgroundRefresh),
        sl<GetAssignments>()(classId, publishedOnly: true, skipBackgroundRefresh: skipBackgroundRefresh),
      ]);

      final assessmentsList = results[0].fold((f) => <Assessment>[], (a) => a as List<Assessment>);
      final assignmentsList = results[1].fold((f) => <Assignment>[], (a) => a as List<Assignment>);

      // Load per-item submission statuses in parallel (local cache reads only, fast)
      final assessmentSubResults = await Future.wait(
        assessmentsList.map((a) => sl<GetStudentSubmission>()(
          GetStudentSubmissionParams(assessmentId: a.id, studentId: studentId),
        )),
      );
      final assignmentSubResults = await Future.wait(
        assignmentsList.map((a) => sl<GetStudentAssignmentSubmission>()(
          GetStudentAssignmentSubmissionParams(assignmentId: a.id, studentId: studentId),
        )),
      );

      state = state.copyWith(
        isLoading: false,
        assessments: [
          for (int i = 0; i < assessmentsList.length; i++)
            AssessmentWithStatus(
              assessment: assessmentsList[i],
              submission: assessmentSubResults[i].fold((_) => null, (s) => s),
            ),
        ],
        assignments: [
          for (int i = 0; i < assignmentsList.length; i++)
            AssignmentWithStatus(
              assignment: assignmentsList[i],
              status: assignmentSubResults[i].fold((_) => null, (s) => s),
            ),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading student details: ${e.toString()}',
      );
    }
  }

  // Public refresh method for manual reloads (e.g., after navigation return)
  Future<void> refresh() => _reloadFromCache();

  // Background fetch: call new server endpoints → cache results → reload submission statuses
  void _backgroundFetchSubmissionStatuses() {
    unawaited(Future.microtask(() async {
      try {
        // Fetch and cache assessment submissions for this student
        final assessmentSubs = await sl<AssessmentRemoteDataSource>()
            .getStudentAssessmentSubmissions(classId: classId, studentId: studentId);

        for (final item in assessmentSubs) {
          await sl<AssessmentLocalDataSource>()
              .cacheSubmissions(item.assessmentId, [item.toSubmissionSummaryModel()]);
        }
      } catch (_) { /* silent fail — offline or server error */ }

      try {
        // Fetch and cache assignment submissions for this student
        final assignmentSubs = await sl<AssignmentRemoteDataSource>()
            .getStudentAssignmentSubmissions(classId: classId, studentId: studentId);

        for (final item in assignmentSubs) {
          await sl<AssignmentLocalDataSource>()
              .cacheSubmissions(item.assignmentId, [item.toSubmissionListItemModel()]);
        }
      } catch (_) { /* silent fail */ }

      // After caching fresh submission data, reload from cache to update UI
      await _reloadFromCache();
    }));
  }
}

final teacherStudentDetailProvider = StateNotifierProvider.autoDispose
    .family<TeacherStudentDetailNotifier, TeacherStudentDetailState,
        ({String classId, String studentId})>(
  (ref, params) => TeacherStudentDetailNotifier(params.classId, params.studentId),
);
