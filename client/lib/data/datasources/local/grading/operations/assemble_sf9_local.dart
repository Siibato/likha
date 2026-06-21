import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/sf9_model.dart';

String _getDescriptor(int grade) {
  if (grade >= 90) return 'Outstanding';
  if (grade >= 85) return 'Very Satisfactory';
  if (grade >= 80) return 'Satisfactory';
  if (grade >= 75) return 'Fairly Satisfactory';
  return 'Did Not Meet Expectations';
}

int _termCount(String termType) {
  switch (termType) {
    case 'semester':
      return 2;
    case 'trimester':
      return 3;
    default:
      return 3;
  }
}

Future<Sf9ResponseModel?> assembleSf9Local(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
) async {
  final db = await localDatabase.database;

  // 1. Get the advisory class
  final classRows = await db.query(
    DbTables.classes,
    where: '${CommonCols.id} = ?',
    whereArgs: [classId],
    limit: 1,
  );
  if (classRows.isEmpty) return null;

  final classRow = classRows.first;
  final isAdvisory = (classRow[ClassesCols.isAdvisory] as int?) == 1;
  if (!isAdvisory) return null;

  final schoolYear = classRow[ClassesCols.schoolYear] as String?;
  final gradeLevel = classRow[ClassesCols.gradeLevel] as String?;
  final section = classRow[ClassesCols.title] as String?;
  final termType =
      classRow[ClassesCols.termType] as String? ?? 'term';
  final teacherName = classRow[ClassesCols.teacherFullName] as String?;
  final numTerms = _termCount(termType);

  // 2. Get student name from users table
  final userRows = await db.query(
    DbTables.users,
    columns: [UsersCols.firstName, UsersCols.lastName],
    where: '${CommonCols.id} = ?',
    whereArgs: [studentId],
    limit: 1,
  );
  if (userRows.isEmpty) return null;
  final firstName = userRows.first[UsersCols.firstName] as String? ?? '';
  final lastName = userRows.first[UsersCols.lastName] as String? ?? '';
  final studentName = '$firstName $lastName'.trim();
  if (studentName.isEmpty) return null;

  // 3. Get learner details
  final learnerRows = await db.query(
    DbTables.learnerDetails,
    where: '${LearnerDetailsCols.userId} = ?',
    whereArgs: [studentId],
    limit: 1,
  );
  final learner = learnerRows.isNotEmpty ? learnerRows.first : null;

  // 4. Get all class_participants for this student (not removed)
  final participantRows = await db.query(
    DbTables.classParticipants,
    columns: [ClassParticipantsCols.classId],
    where:
        '${ClassParticipantsCols.userId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
    whereArgs: [studentId],
  );
  if (participantRows.isEmpty) return null;

  final enrolledClassIds = participantRows
      .map((r) => r[ClassParticipantsCols.classId] as String?)
      .where((id) => id != null && id.isNotEmpty)
      .toList()
      .cast<String>();

  // 5. Filter class IDs by matching school_year
  final classIdPlaceholders = enrolledClassIds.map((_) => '?').join(', ');
  final classMatches = await db.rawQuery(
    'SELECT ${CommonCols.id}, ${ClassesCols.title} FROM ${DbTables.classes} '
    'WHERE ${CommonCols.id} IN ($classIdPlaceholders) '
    'AND ${ClassesCols.schoolYear} = ? '
    'AND ${ClassesCols.isAdvisory} = 0 '
    'AND ${CommonCols.deletedAt} IS NULL',
    [...enrolledClassIds, schoolYear],
  );

  if (classMatches.isEmpty) return null;

  // 6. For each enrolled class, get term_grades
  final subjects = <Sf9SubjectRowModel>[];
  final termSums = List<List<int>>.generate(numTerms, (_) => []);
  final finalGrades = <int>[];

  for (final classMatch in classMatches) {
    final cid = classMatch[CommonCols.id] as String;
    final ctitle = classMatch[ClassesCols.title] as String? ?? '';

    final pgRows = await db.query(
      DbTables.termGrades,
      where:
          '${TermGradesCols.classId} = ? AND ${TermGradesCols.studentId} = ?',
      whereArgs: [cid, studentId],
    );

    final termVals = List<int?>.filled(numTerms, null);
    for (final pg in pgRows) {
      final termNum = pg[TermGradesCols.termNumber] as int?;
      final transmuted = pg[TermGradesCols.transmutedGrade] as int?;
      if (termNum != null && transmuted != null) {
        final idx = termNum - 1;
        if (idx >= 0 && idx < numTerms) {
          termVals[idx] = transmuted;
          termSums[idx].add(transmuted);
        }
      }
    }

    final transmuted = termVals.whereType<int>().toList();
    final int? finalGrade;
    if (transmuted.isEmpty) {
      finalGrade = null;
    } else {
      final avg = transmuted.reduce((a, b) => a + b) / transmuted.length;
      finalGrade = avg.round();
    }

    if (finalGrade != null) {
      finalGrades.add(finalGrade);
    }

    final descriptor = finalGrade != null ? _getDescriptor(finalGrade) : null;

    subjects.add(Sf9SubjectRowModel(
      classTitle: ctitle,
      termGrades: termVals,
      finalGrade: finalGrade,
      descriptor: descriptor,
    ));
  }

  // 7. Compute general average
  int? computeAvg(List<int> grades) {
    if (grades.isEmpty) return null;
    final avg = grades.reduce((a, b) => a + b) / grades.length;
    return avg.round();
  }

  final finalAverage = computeAvg(finalGrades);
  final gaDescriptor =
      finalAverage != null ? _getDescriptor(finalAverage) : null;

  final generalAverage = Sf9TermAveragesModel(
    termGrades: termSums.map((s) => computeAvg(s)).toList(),
    finalAverage: finalAverage,
    descriptor: gaDescriptor,
  );

  return Sf9ResponseModel(
    studentId: studentId,
    studentName: studentName,
    gradeLevel: gradeLevel,
    schoolYear: schoolYear,
    section: section,
    lrn: learner?[LearnerDetailsCols.lrn] as String?,
    age: learner?[LearnerDetailsCols.age] as int?,
    sex: learner?[LearnerDetailsCols.sex] as String?,
    trackStrand: learner?[LearnerDetailsCols.trackStrand] as String?,
    curriculum: learner?[LearnerDetailsCols.curriculum] as String?,
    teacherName: teacherName,
    termType: termType,
    subjects: subjects,
    generalAverage: generalAverage,
    coreValues: await _getLocalCoreValues(db, classId, studentId),
    attendance: await _getLocalAttendance(db, classId, studentId, schoolYear),
  );
}

Future<List<Sf9AttendanceRecordModel>> _getLocalAttendance(
  dynamic db,
  String classId,
  String studentId,
  String? schoolYear,
) async {
  final rows = await db.query(
    DbTables.attendanceRecords,
    where:
        '${AttendanceRecordsCols.studentId} = ? AND ${AttendanceRecordsCols.classId} = ? AND ${AttendanceRecordsCols.schoolYear} = ? AND ${AttendanceRecordsCols.deletedAt} IS NULL',
    whereArgs: [studentId, classId, schoolYear],
  );
  return rows
      .map((row) => Sf9AttendanceRecordModel(
            month: row[AttendanceRecordsCols.month] as String,
            schoolDays: row[AttendanceRecordsCols.schoolDays] as int,
            daysPresent: row[AttendanceRecordsCols.daysPresent] as int,
          ))
      .toList();
}

Future<List<Sf9CoreValueMarkingModel>> _getLocalCoreValues(
  dynamic db,
  String classId,
  String studentId,
) async {
  final rows = await db.query(
    DbTables.coreValuesRecords,
    where:
        '${CoreValuesRecordsCols.studentId} = ? AND ${CoreValuesRecordsCols.classId} = ? AND ${CoreValuesRecordsCols.deletedAt} IS NULL',
    whereArgs: [studentId, classId],
  );
  return rows
      .map((row) => Sf9CoreValueMarkingModel(
            coreValueId: row[CoreValuesRecordsCols.coreValueId] as int,
            termNumber: row[CoreValuesRecordsCols.termNumber] as int,
            marking: row[CoreValuesRecordsCols.marking] as String,
          ))
      .toList();
}
