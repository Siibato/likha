import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> clearAllDataIncrementally(LocalDatabase localDatabase) async {
  final db = await localDatabase.database;

  final classRows = await db.query(DbTables.classes, columns: ['id']);
  final classIds = classRows.map((r) => r['id'] as String).toList();
  final totalClasses = classIds.length;

  final totalSteps = totalClasses + 8;
  int step = 0;

  void emit(String phase) {
    step++;
    localDatabase.logoutProgressNotifier.value = LogoutProgress(
      phase: phase,
      currentStep: step,
      totalSteps: totalSteps,
    );
  }

  for (int i = 0; i < totalClasses; i++) {
    final classId = classIds[i];
    emit('Clearing class ${i + 1} of $totalClasses');

    await db.transaction((txn) async {
      await txn.delete(DbTables.assessmentSubmissions,
          where: 'assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?)',
          whereArgs: [classId]);
      await txn.delete(DbTables.submissionAnswers,
          where: 'submission_id IN (SELECT id FROM ${DbTables.assessmentSubmissions} WHERE assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?))',
          whereArgs: [classId]);
      await txn.delete(DbTables.submissionAnswerItems,
          where: 'submission_answer_id IN (SELECT id FROM ${DbTables.submissionAnswers} WHERE submission_id IN (SELECT id FROM ${DbTables.assessmentSubmissions} WHERE assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?)))',
          whereArgs: [classId]);
      await txn.delete(DbTables.assessmentQuestions,
          where: 'assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?)',
          whereArgs: [classId]);
      await txn.delete(DbTables.questionChoices,
          where: 'question_id IN (SELECT id FROM ${DbTables.assessmentQuestions} WHERE assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?))',
          whereArgs: [classId]);
      await txn.delete(DbTables.answerKeys,
          where: 'question_id IN (SELECT id FROM ${DbTables.assessmentQuestions} WHERE assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?))',
          whereArgs: [classId]);
      await txn.delete(DbTables.answerKeyAcceptableAnswers,
          where: 'answer_key_id IN (SELECT id FROM ${DbTables.answerKeys} WHERE question_id IN (SELECT id FROM ${DbTables.assessmentQuestions} WHERE assessment_id IN (SELECT id FROM ${DbTables.assessments} WHERE class_id = ?)))',
          whereArgs: [classId]);
      await txn.delete(DbTables.assessments,
          where: 'class_id = ?', whereArgs: [classId]);

      await txn.delete(DbTables.assignmentSubmissions,
          where: 'assignment_id IN (SELECT id FROM ${DbTables.assignments} WHERE class_id = ?)',
          whereArgs: [classId]);
      await txn.delete(DbTables.submissionFiles,
          where: 'submission_id IN (SELECT id FROM ${DbTables.assignmentSubmissions} WHERE assignment_id IN (SELECT id FROM ${DbTables.assignments} WHERE class_id = ?))',
          whereArgs: [classId]);
      await txn.delete(DbTables.assignments,
          where: 'class_id = ?', whereArgs: [classId]);

      await txn.delete(DbTables.materialFiles,
          where: 'material_id IN (SELECT id FROM ${DbTables.learningMaterials} WHERE class_id = ?)',
          whereArgs: [classId]);
      await txn.delete(DbTables.learningMaterials,
          where: 'class_id = ?', whereArgs: [classId]);

      await txn.delete(DbTables.gradeScores,
          where: 'grade_item_id IN (SELECT id FROM ${DbTables.gradeItems} WHERE class_id = ?)',
          whereArgs: [classId]);
      await txn.delete(DbTables.gradeItems,
          where: 'class_id = ?', whereArgs: [classId]);
      await txn.delete(DbTables.gradeRecord,
          where: 'class_id = ?', whereArgs: [classId]);
      await txn.delete(DbTables.termGrades,
          where: 'class_id = ?', whereArgs: [classId]);

      await txn.delete(DbTables.tosCompetencies,
          where: 'tos_id IN (SELECT id FROM ${DbTables.tableOfSpecifications} WHERE class_id = ?)',
          whereArgs: [classId]);
      await txn.delete(DbTables.tableOfSpecifications,
          where: 'class_id = ?', whereArgs: [classId]);

      await txn.delete(DbTables.attendanceRecords,
          where: 'class_id = ?', whereArgs: [classId]);
      await txn.delete(DbTables.coreValuesRecords,
          where: 'class_id = ?', whereArgs: [classId]);

      await txn.delete(DbTables.classParticipants,
          where: 'class_id = ?', whereArgs: [classId]);
      await txn.delete(DbTables.classes,
          where: 'id = ?', whereArgs: [classId]);
    });
  }

  emit('Clearing student records');
  await db.delete(DbTables.learnerDetails);
  await db.delete(DbTables.teacherDetails);
  await db.delete(DbTables.studentSchoolHistory);

  emit('Clearing previous school data');
  await db.delete(DbTables.previousSchoolTermGrades);
  await db.delete(DbTables.previousSchoolAttendance);
  await db.delete(DbTables.previousSchoolSubjects);

  emit('Clearing sync data');
  await db.delete(DbTables.syncQueue);
  await db.delete(DbTables.studentResultsCache);
  await db.delete(DbTables.validationMetadata);
  await db.delete(DbTables.syncMetadata,
      where: 'key != ?', whereArgs: ['device_id']);

  emit('Clearing activity logs');
  await db.delete(DbTables.activityLogs);

  emit('Clearing user accounts');
  await db.delete(DbTables.refreshTokens);
  await db.delete(DbTables.users);

  emit('Clearing school details');
  await db.delete(DbTables.schoolDetails);
  await db.delete(DbTables.melcs);

  localDatabase.logoutProgressNotifier.value = null;
}
