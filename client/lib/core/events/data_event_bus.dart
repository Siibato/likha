import 'dart:async';

import 'package:likha/core/logging/core_logger.dart';

/// Event bus that bridges the data layer (repositories) and the presentation
/// layer (notifiers). Repositories emit events; notifiers listen and reload.
///
/// Each stream carries the classId of the affected resource (or null for
/// class-level events with no class scope). Notifiers compare the emitted
/// classId against the one they are currently displaying and only reload
/// if they match.
class DataEventBus {
  final StreamController<String?> _assessments =
      StreamController<String?>.broadcast();
  final StreamController<String?> _assessmentDetail =
      StreamController<String?>.broadcast();
  final StreamController<String?> _assignments =
      StreamController<String?>.broadcast();
  final StreamController<String?> _materials =
      StreamController<String?>.broadcast();
  final StreamController<String> _submissionDetail =
      StreamController<String>.broadcast();
  final StreamController<void> _classes =
      StreamController<void>.broadcast();
  final StreamController<String> _classDetail =
      StreamController<String>.broadcast();
  final StreamController<void> _currentUser =
      StreamController<void>.broadcast();
  final StreamController<String> _gradeItems =
      StreamController<String>.broadcast();
  final StreamController<String> _grades =
      StreamController<String>.broadcast();
  final StreamController<String> _gradeSummary =
      StreamController<String>.broadcast();
  final StreamController<String> _activityLogs =
      StreamController<String>.broadcast();
  final StreamController<String> _statistics =
      StreamController<String>.broadcast();
  final StreamController<String> _studentResults =
      StreamController<String>.broadcast();
  final StreamController<String> _tosList =
      StreamController<String>.broadcast();
  final StreamController<String> _tosDetail =
      StreamController<String>.broadcast();
  final StreamController<void> _accounts =
      StreamController<void>.broadcast();
  final StreamController<String> _finalGrades =
      StreamController<String>.broadcast();
  final StreamController<String> _generalAverages =
      StreamController<String>.broadcast();
  final StreamController<String> _myGradeDetail =
      StreamController<String>.broadcast();
  final StreamController<String> _sf9 =
      StreamController<String>.broadcast();
  final StreamController<String> _sf10 =
      StreamController<String>.broadcast();
  final StreamController<String> _learnerDetails =
      StreamController<String>.broadcast();
  final StreamController<String> _attendanceRecords =
      StreamController<String>.broadcast();
  final StreamController<String> _coreValuesRecords =
      StreamController<String>.broadcast();
  final StreamController<String> _schoolHistory =
      StreamController<String>.broadcast();
  final StreamController<String> _previousSubjects =
      StreamController<String>.broadcast();
  final StreamController<String> _previousAttendance =
      StreamController<String>.broadcast();
  final StreamController<String> _participants =
      StreamController<String>.broadcast();
  final StreamController<String> _studentSubmissions =
      StreamController<String>.broadcast();
  final StreamController<String> _studentAssignmentSubmissions =
      StreamController<String>.broadcast();
  final StreamController<void> _schoolDetails =
      StreamController<void>.broadcast();

  Stream<String?> get onAssessmentsChanged => _assessments.stream;
  Stream<String?> get onAssessmentDetailChanged => _assessmentDetail.stream;
  Stream<String?> get onAssignmentsChanged => _assignments.stream;
  Stream<String?> get onMaterialsChanged   => _materials.stream;
  Stream<String>  get onSubmissionDetailChanged => _submissionDetail.stream;
  Stream<void>    get onClassesChanged      => _classes.stream;
  Stream<String>  get onClassDetailChanged  => _classDetail.stream;
  Stream<void>    get onCurrentUserChanged  => _currentUser.stream;
  Stream<String>  get onGradeItemsChanged   => _gradeItems.stream;
  Stream<String>  get onGradesChanged       => _grades.stream;
  Stream<String>  get onGradeSummaryChanged => _gradeSummary.stream;
  Stream<String>  get onActivityLogsChanged => _activityLogs.stream;
  Stream<String>  get onStatisticsChanged   => _statistics.stream;
  Stream<String>  get onStudentResultsChanged => _studentResults.stream;
  Stream<String>  get onTosListChanged      => _tosList.stream;
  Stream<String>  get onTosDetailChanged    => _tosDetail.stream;
  Stream<void>    get onAccountsChanged      => _accounts.stream;
  Stream<String>  get onFinalGradesChanged   => _finalGrades.stream;
  Stream<String>  get onGeneralAveragesChanged => _generalAverages.stream;
  Stream<String>  get onMyGradeDetailChanged  => _myGradeDetail.stream;
  Stream<String>  get onSf9Changed            => _sf9.stream;
  Stream<String>  get onSf10Changed           => _sf10.stream;
  Stream<String>  get onLearnerDetailsChanged  => _learnerDetails.stream;
  Stream<String>  get onAttendanceChanged      => _attendanceRecords.stream;
  Stream<String>  get onCoreValuesChanged       => _coreValuesRecords.stream;
  Stream<String>  get onSchoolHistoryChanged    => _schoolHistory.stream;
  Stream<String>  get onPreviousSubjectsChanged => _previousSubjects.stream;
  Stream<String>  get onPreviousAttendanceChanged => _previousAttendance.stream;
  Stream<String>  get onParticipantsChanged   => _participants.stream;
  Stream<String>  get onStudentSubmissionsChanged => _studentSubmissions.stream;
  Stream<String>  get onStudentAssignmentSubmissionsChanged => _studentAssignmentSubmissions.stream;
  Stream<void>    get onSchoolDetailsChanged    => _schoolDetails.stream;

  void notifyAssessmentsChanged(String classId) => _assessments.add(classId);
  void notifyAssessmentDetailChanged(String assessmentId) => _assessmentDetail.add(assessmentId);
  void notifyAssignmentsChanged(String classId) => _assignments.add(classId);
  void notifyMaterialsChanged(String classId) {
    CoreLogger.instance.log('🔔 notifyMaterialsChanged fired with classId: $classId');
    _materials.add(classId);
  }
  void notifySubmissionDetailChanged(String submissionId) {
    CoreLogger.instance.log('🔔 notifySubmissionDetailChanged fired with submissionId: $submissionId');
    _submissionDetail.add(submissionId);
  }
  void notifyClassesChanged()                    => _classes.add(null);
  void notifyClassDetailChanged(String classId) => _classDetail.add(classId);
  void notifyCurrentUserChanged()              => _currentUser.add(null);
  void notifyGradeItemsChanged(String classId)  => _gradeItems.add(classId);
  void notifyGradesChanged(String classId)      => _grades.add(classId);
  void notifyGradeSummaryChanged(String classId) => _gradeSummary.add(classId);
  void notifyActivityLogsChanged(String userId)  => _activityLogs.add(userId);
  void notifyStatisticsChanged(String assessmentId) => _statistics.add(assessmentId);
  void notifyStudentResultsChanged(String submissionId) => _studentResults.add(submissionId);
  void notifyTosListChanged(String classId)       => _tosList.add(classId);
  void notifyTosDetailChanged(String tosId)       => _tosDetail.add(tosId);
  void notifyAccountsChanged()                      => _accounts.add(null);
  void notifyFinalGradesChanged(String classId)     => _finalGrades.add(classId);
  void notifyGeneralAveragesChanged(String classId) => _generalAverages.add(classId);
  void notifyMyGradeDetailChanged(String classId)   => _myGradeDetail.add(classId);
  void notifySf9Changed(String classId)             => _sf9.add(classId);
  void notifySf10Changed(String classId)            => _sf10.add(classId);
  void notifyLearnerDetailsChanged(String studentId) => _learnerDetails.add(studentId);
  void notifyAttendanceChanged(String studentId)     => _attendanceRecords.add(studentId);
  void notifyCoreValuesChanged(String studentId)     => _coreValuesRecords.add(studentId);
  void notifySchoolHistoryChanged(String studentId)  => _schoolHistory.add(studentId);
  void notifyPreviousSubjectsChanged(String historyId) => _previousSubjects.add(historyId);
  void notifyPreviousAttendanceChanged(String historyId) => _previousAttendance.add(historyId);
  void notifyParticipantsChanged(String classId)  => _participants.add(classId);
  void notifyStudentSubmissionsChanged(String assessmentId) => _studentSubmissions.add(assessmentId);
  void notifyStudentAssignmentSubmissionsChanged(String assignmentId) => _studentAssignmentSubmissions.add(assignmentId);
  void notifySchoolDetailsChanged() => _schoolDetails.add(null);

  void dispose() {
    _assessments.close();
    _assessmentDetail.close();
    _assignments.close();
    _materials.close();
    _submissionDetail.close();
    _classes.close();
    _classDetail.close();
    _currentUser.close();
    _gradeItems.close();
    _grades.close();
    _gradeSummary.close();
    _activityLogs.close();
    _statistics.close();
    _studentResults.close();
    _tosList.close();
    _tosDetail.close();
    _accounts.close();
    _finalGrades.close();
    _generalAverages.close();
    _myGradeDetail.close();
    _sf9.close();
    _sf10.close();
    _learnerDetails.close();
    _attendanceRecords.close();
    _coreValuesRecords.close();
    _schoolHistory.close();
    _previousSubjects.close();
    _previousAttendance.close();
    _participants.close();
    _studentSubmissions.close();
    _studentAssignmentSubmissions.close();
    _schoolDetails.close();
  }
}
