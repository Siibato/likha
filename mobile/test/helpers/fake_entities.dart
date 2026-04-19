import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/domain/learning_materials/entities/material_detail.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

/// Test data builders for domain entities
class FakeEntities {
  // ===== Auth Entities =====
  
  static User user({
    String? id,
    String? username,
    String? fullName,
    String? role,
    String? accountStatus,
    bool? isActive,
  }) => User(
    id: id ?? 'user-1',
    username: username ?? 'testuser',
    fullName: fullName ?? 'Test User',
    role: role ?? 'student',
    accountStatus: accountStatus ?? 'activated',
    isActive: isActive ?? true,
    createdAt: DateTime(2024, 1, 1),
  );

  static User teacher({String? id, String? username}) => user(
    id: id,
    username: username,
    role: 'teacher',
  );

  static User admin({String? id, String? username}) => user(
    id: id,
    username: username,
    role: 'admin',
  );

  static CheckUsernameResult checkUsernameResult({
    String? username,
    String? accountStatus,
    String? fullName,
  }) => CheckUsernameResult(
    username: username ?? 'testuser',
    accountStatus: accountStatus ?? 'pending_activation',
    fullName: fullName,
  );

  static ActivityLog activityLog({
    String? id,
    String? userId,
    String? action,
    String? details,
  }) => ActivityLog(
    id: id ?? 'log-1',
    userId: userId ?? 'user-1',
    action: action ?? 'login',
    details: details,
    createdAt: DateTime(2024, 1, 1),
  );

  // ===== Assignment Entities =====
  
  static Assignment assignment({
    String? id,
    String? classId,
    String? title,
    String? instructions,
    int? totalPoints,
    bool? allowsTextSubmission,
    bool? allowsFileSubmission,
    bool? isPublished,
    int? orderIndex,
  }) => Assignment(
    id: id ?? 'assignment-1',
    classId: classId ?? 'class-1',
    title: title ?? 'Test Assignment',
    instructions: instructions ?? 'Complete the exercises',
    totalPoints: totalPoints ?? 100,
    allowsTextSubmission: allowsTextSubmission ?? true,
    allowsFileSubmission: allowsFileSubmission ?? false,
    dueAt: DateTime(2024, 12, 31),
    isPublished: isPublished ?? true,
    orderIndex: orderIndex ?? 0,
    submissionCount: 0,
    gradedCount: 0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static AssignmentSubmission assignmentSubmission({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? status,
    int? score,
  }) => AssignmentSubmission(
    id: id ?? 'submission-1',
    assignmentId: assignmentId ?? 'assignment-1',
    studentId: studentId ?? 'student-1',
    studentName: studentName ?? 'Student One',
    status: status ?? 'submitted',
    textContent: null,
    score: score,
    files: const [],
    submittedAt: DateTime(2024, 1, 15),
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  );

  static SubmissionFile submissionFile({
    String? id,
    String? fileName,
    String? fileType,
    int? fileSize,
  }) => SubmissionFile(
    id: id ?? 'file-1',
    fileName: fileName ?? 'document.pdf',
    fileType: fileType ?? 'pdf',
    fileSize: fileSize ?? 1024,
    uploadedAt: DateTime(2024, 1, 15),
  );

  static StudentAssignmentStatus studentAssignmentStatus({
    String? submissionId,
    String? status,
    int? score,
  }) => StudentAssignmentStatus(
    submissionId: submissionId ?? 'submission-1',
    status: status ?? 'graded',
    score: score ?? 85,
  );

  static SubmissionListItem submissionListItem({
    String? id,
    String? studentId,
    String? studentName,
    String? studentUsername,
    String? status,
    int? score,
  }) => SubmissionListItem(
    id: id ?? 'submission-1',
    studentId: studentId ?? 'student-1',
    studentName: studentName ?? 'Student One',
    studentUsername: studentUsername ?? 'student1',
    status: status ?? 'graded',
    score: score ?? 85,
    submittedAt: DateTime(2024, 1, 15),
  );

  // ===== Assessment Entities =====
  
  static Assessment assessment({
    String? id,
    String? classId,
    String? title,
    String? description,
    int? timeLimitMinutes,
    bool? isPublished,
    int? questionCount,
  }) => Assessment(
    id: id ?? 'assessment-1',
    classId: classId ?? 'class-1',
    title: title ?? 'Test Assessment',
    description: description,
    timeLimitMinutes: timeLimitMinutes ?? 60,
    openAt: DateTime(2024, 1, 1),
    closeAt: DateTime(2024, 12, 31),
    showResultsImmediately: true,
    resultsReleased: false,
    isPublished: isPublished ?? true,
    orderIndex: 0,
    totalPoints: 10,
    questionCount: questionCount ?? 10,
    submissionCount: 0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static Question multipleChoiceQuestion({
    String? id,
    String? assessmentId,
    String? questionText,
    int? orderIndex,
    List<String>? choices,
  }) => Question(
    id: id ?? 'question-1',
    assessmentId: assessmentId ?? 'assessment-1',
    questionText: questionText ?? 'What is 2+2?',
    questionType: 'multiple_choice',
    orderIndex: orderIndex ?? 0,
    points: 1,
    isMultiSelect: false,
    choices: choices?.asMap().entries.map((e) => Choice(
      id: 'choice-${e.key}',
      choiceText: e.value,
      isCorrect: e.value == '4',
      orderIndex: e.key,
    )).toList() ?? [
      const Choice(id: 'choice-0', choiceText: '3', isCorrect: false, orderIndex: 0),
      const Choice(id: 'choice-1', choiceText: '4', isCorrect: true, orderIndex: 1),
      const Choice(id: 'choice-2', choiceText: '5', isCorrect: false, orderIndex: 2),
      const Choice(id: 'choice-3', choiceText: '6', isCorrect: false, orderIndex: 3),
    ],
    correctAnswers: const [CorrectAnswer(id: 'answer-1', answerText: '4')],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static Question essayQuestion({
    String? id,
    String? assessmentId,
    String? questionText,
    int? orderIndex,
  }) => Question(
    id: id ?? 'question-2',
    assessmentId: assessmentId ?? 'assessment-1',
    questionText: questionText ?? 'Explain your answer.',
    questionType: 'essay',
    orderIndex: orderIndex ?? 1,
    points: 5,
    isMultiSelect: false,
    choices: null,
    correctAnswers: null,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  // ===== Class Entities =====
  
  static ClassEntity classEntity({
    String? id,
    String? title,
    String? teacherId,
    String? teacherUsername,
    String? teacherFullName,
    bool? isAdvisory,
    bool? isArchived,
    int? studentCount,
  }) => ClassEntity(
    id: id ?? 'class-1',
    title: title ?? 'Test Class',
    teacherId: teacherId ?? 'teacher-1',
    teacherUsername: teacherUsername ?? 'teacher1',
    teacherFullName: teacherFullName ?? 'Teacher One',
    isArchived: isArchived ?? false,
    isAdvisory: isAdvisory ?? false,
    studentCount: studentCount ?? 30,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static ClassDetail classDetail({
    String? id,
    String? title,
    String? teacherId,
    bool? isArchived,
    bool? isAdvisory,
    List<Participant>? students,
  }) => ClassDetail(
    id: id ?? 'class-1',
    title: title ?? 'Test Class',
    description: null,
    teacherId: teacherId ?? 'teacher-1',
    isArchived: isArchived ?? false,
    isAdvisory: isAdvisory ?? false,
    students: students ?? const [],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static Participant participant({
    String? id,
    User? student,
  }) => Participant(
    id: id ?? 'participant-1',
    student: student ?? user(),
    joinedAt: DateTime(2024, 1, 15),
  );

  // ===== Grading Entities =====
  
  static GradeConfig gradeConfig({
    String? id,
    String? classId,
    int? gradingPeriodNumber,
    double? wwWeight,
    double? ptWeight,
    double? qaWeight,
  }) => GradeConfig(
    id: id ?? 'config-1',
    classId: classId ?? 'class-1',
    gradingPeriodNumber: gradingPeriodNumber ?? 1,
    wwWeight: wwWeight ?? 30.0,
    ptWeight: ptWeight ?? 50.0,
    qaWeight: qaWeight ?? 20.0,
  );

  static GradeItem gradeItem({
    String? id,
    String? classId,
    String? title,
    String? component,
    int? gradingPeriodNumber,
    double? totalPoints,
    String? sourceType,
    String? sourceId,
  }) => GradeItem(
    id: id ?? 'item-1',
    classId: classId ?? 'class-1',
    title: title ?? 'Quiz 1',
    component: component ?? 'written_work',
    gradingPeriodNumber: gradingPeriodNumber ?? 1,
    totalPoints: totalPoints ?? 100.0,
    sourceType: sourceType ?? 'manual',
    sourceId: sourceId,
    orderIndex: 0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static GradeScore gradeScore({
    String? id,
    String? gradeItemId,
    String? studentId,
    double? score,
    bool? isAutoPopulated,
    double? overrideScore,
  }) => GradeScore(
    id: id ?? 'score-1',
    gradeItemId: gradeItemId ?? 'item-1',
    studentId: studentId ?? 'student-1',
    score: score ?? 85.0,
    isAutoPopulated: isAutoPopulated ?? false,
    overrideScore: overrideScore,
  );

  static PeriodGrade periodGrade({
    String? id,
    String? classId,
    String? studentId,
    int? gradingPeriodNumber,
    double? initialGrade,
    int? transmutedGrade,
    bool? isLocked,
    bool? isPreview,
  }) => PeriodGrade(
    id: id ?? 'grade-1',
    classId: classId ?? 'class-1',
    studentId: studentId ?? 'student-1',
    gradingPeriodNumber: gradingPeriodNumber ?? 1,
    initialGrade: initialGrade ?? 85.0,
    transmutedGrade: transmutedGrade ?? 88,
    isLocked: isLocked ?? false,
    isPreview: isPreview ?? false,
    computedAt: DateTime(2024, 1, 15),
  );

  // ===== TOS Entities =====
  
  static TableOfSpecifications tos({
    String? id,
    String? classId,
    int? gradingPeriodNumber,
    String? title,
    String? classificationMode,
    int? totalItems,
    String? timeUnit,
  }) => TableOfSpecifications(
    id: id ?? 'tos-1',
    classId: classId ?? 'class-1',
    gradingPeriodNumber: gradingPeriodNumber ?? 1,
    title: title ?? 'TOS for Q1',
    classificationMode: classificationMode ?? 'traditional',
    totalItems: totalItems ?? 50,
    timeUnit: timeUnit ?? 'days',
    easyPercentage: 30.0,
    mediumPercentage: 50.0,
    hardPercentage: 20.0,
    rememberingPercentage: 20.0,
    understandingPercentage: 30.0,
    applyingPercentage: 25.0,
    analyzingPercentage: 15.0,
    evaluatingPercentage: 5.0,
    creatingPercentage: 5.0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static TosCompetency tosCompetency({
    String? id,
    String? tosId,
    String? competencyCode,
    String? competencyText,
    int? timeUnitsTaught,
    int? orderIndex,
  }) => TosCompetency(
    id: id ?? 'competency-1',
    tosId: tosId ?? 'tos-1',
    competencyCode: competencyCode ?? 'M7NS-Ia-1',
    competencyText: competencyText ?? 'Demonstrates understanding of...',
    timeUnitsTaught: timeUnitsTaught ?? 5,
    orderIndex: orderIndex ?? 0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  // ===== Learning Material Entities =====
  
  static LearningMaterial learningMaterial({
    String? id,
    String? classId,
    String? title,
    String? contentText,
    int? orderIndex,
  }) => LearningMaterial(
    id: id ?? 'material-1',
    classId: classId ?? 'class-1',
    title: title ?? 'Lesson 1',
    description: null,
    contentText: contentText,
    orderIndex: orderIndex ?? 0,
    fileCount: 0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static MaterialDetail materialDetail({
    String? id,
    String? classId,
    String? title,
  }) => MaterialDetail(
    id: id ?? 'material-1',
    classId: classId ?? 'class-1',
    title: title ?? 'Lesson 1',
    description: null,
    contentText: 'Lesson content here',
    files: const [],
    orderIndex: 0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static MaterialFile materialFile({
    String? id,
    String? fileName,
    String? fileType,
    int? fileSize,
  }) => MaterialFile(
    id: id ?? 'file-1',
    fileName: fileName ?? 'handout.pdf',
    fileType: fileType ?? 'pdf',
    fileSize: fileSize ?? 1024,
    uploadedAt: DateTime(2024, 1, 1),
  );
}
