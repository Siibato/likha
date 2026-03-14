import 'dart:async';

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

  Stream<String?> get onAssessmentsChanged => _assessments.stream;
  Stream<String?> get onAssessmentDetailChanged => _assessmentDetail.stream;
  Stream<String?> get onAssignmentsChanged => _assignments.stream;
  Stream<String?> get onMaterialsChanged   => _materials.stream;
  Stream<String>  get onSubmissionDetailChanged => _submissionDetail.stream;
  Stream<void>    get onClassesChanged      => _classes.stream;

  void notifyAssessmentsChanged(String classId) => _assessments.add(classId);
  void notifyAssessmentDetailChanged(String assessmentId) => _assessmentDetail.add(assessmentId);
  void notifyAssignmentsChanged(String classId) => _assignments.add(classId);
  void notifyMaterialsChanged(String classId) {
    print('[EVENT_BUS] 🔔 notifyMaterialsChanged fired with classId: $classId');
    _materials.add(classId);
  }
  void notifySubmissionDetailChanged(String submissionId) {
    print('[EVENT_BUS] 🔔 notifySubmissionDetailChanged fired with submissionId: $submissionId');
    _submissionDetail.add(submissionId);
  }
  void notifyClassesChanged()                    => _classes.add(null);

  void dispose() {
    _assessments.close();
    _assessmentDetail.close();
    _assignments.close();
    _materials.close();
    _submissionDetail.close();
    _classes.close();
  }
}
