import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/student_records/sf10_response_model.dart';

String _getDescriptor(int grade) {
  if (grade >= 90) return 'Outstanding';
  if (grade >= 85) return 'Very Satisfactory';
  if (grade >= 80) return 'Satisfactory';
  if (grade >= 75) return 'Fairly Satisfactory';
  return 'Did Not Meet Expectations';
}

int _periodCount(String gradingPeriodType) {
  switch (gradingPeriodType) {
    case 'semester':
      return 2;
    case 'trimester':
      return 3;
    default:
      return 4;
  }
}

Future<Sf10ResponseModel?> assembleSf10Local(
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
  final gradingPeriodType =
      classRow[ClassesCols.gradingPeriodType] as String? ?? 'quarter';
  final numPeriods = _periodCount(gradingPeriodType);

  // 2. Get student name
  final userRows = await db.query(
    DbTables.users,
    columns: [UsersCols.fullName],
    where: '${CommonCols.id} = ?',
    whereArgs: [studentId],
    limit: 1,
  );
  if (userRows.isEmpty) return null;
  final studentName =
      userRows.first[UsersCols.fullName] as String? ?? 'Unknown Student';

  // 3. Get learner details
  final learnerRows = await db.query(
    DbTables.learnerDetails,
    where: '${LearnerDetailsCols.userId} = ?',
    whereArgs: [studentId],
    limit: 1,
  );
  final learner = learnerRows.isNotEmpty ? learnerRows.first : null;

  // 4. Get enrolled classes for current school year (same as SF9)
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

  final classIdPlaceholders = enrolledClassIds.map((_) => '?').join(', ');
  final classMatches = await db.rawQuery(
    'SELECT ${CommonCols.id}, ${ClassesCols.title} FROM ${DbTables.classes} '
    'WHERE ${CommonCols.id} IN ($classIdPlaceholders) '
    'AND ${ClassesCols.schoolYear} = ? '
    'AND ${CommonCols.deletedAt} IS NULL',
    [...enrolledClassIds, schoolYear],
  );

  // 5. Build current year scholastic record (same as SF9 subjects)
  final subjects = <Sf10SubjectRowModel>[];
  final finalGrades = <int>[];

  for (final classMatch in classMatches) {
    final cid = classMatch[CommonCols.id] as String;
    final ctitle = classMatch[ClassesCols.title] as String? ?? '';

    final pgRows = await db.query(
      DbTables.periodGrades,
      where:
          '${PeriodGradesCols.classId} = ? AND ${PeriodGradesCols.studentId} = ?',
      whereArgs: [cid, studentId],
    );

    final periodVals = List<int?>.filled(numPeriods, null);
    for (final pg in pgRows) {
      final periodNum = pg[PeriodGradesCols.gradingPeriodNumber] as int?;
      final transmuted = pg[PeriodGradesCols.transmutedGrade] as int?;
      if (periodNum != null && transmuted != null) {
        final idx = periodNum - 1;
        if (idx >= 0 && idx < numPeriods) {
          periodVals[idx] = transmuted;
        }
      }
    }

    final transmuted = periodVals.whereType<int>().toList();
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

    subjects.add(Sf10SubjectRowModel(
      classTitle: ctitle,
      periodGrades: periodVals,
      finalGrade: finalGrade,
      descriptor: descriptor,
    ));
  }

  // 6. Get current year attendance
  final attendanceRows = await db.query(
    DbTables.attendanceRecords,
    where:
        '${AttendanceRecordsCols.studentId} = ? AND ${AttendanceRecordsCols.classId} = ?',
    whereArgs: [studentId, classId],
  );

  final currentAttendance = attendanceRows
      .map((a) => Sf10AttendanceMonthModel(
            month: a[AttendanceRecordsCols.month] as String? ?? '',
            schoolDays: a[AttendanceRecordsCols.schoolDays] as int? ?? 0,
            daysPresent: a[AttendanceRecordsCols.daysPresent] as int? ?? 0,
            daysAbsent: a[AttendanceRecordsCols.daysAbsent] as int? ?? 0,
          ))
      .toList();

  // 7. Compute current year final average
  int? computeAvg(List<int> grades) {
    if (grades.isEmpty) return null;
    final avg = grades.reduce((a, b) => a + b) / grades.length;
    return avg.round();
  }

  final currentFinalAvg = computeAvg(finalGrades);
  final currentDescriptor =
      currentFinalAvg != null ? _getDescriptor(currentFinalAvg) : null;

  final scholasticRecords = <Sf10YearRecordModel>[
    Sf10YearRecordModel(
      schoolYear: schoolYear ?? '',
      gradeLevel: gradeLevel ?? '',
      section: section,
      schoolName: '',
      subjects: subjects,
      finalAverage: currentFinalAvg,
      descriptor: currentDescriptor,
      attendance: currentAttendance,
    ),
  ];

  // 8. Get school history (previous schools)
  final historyRows = await db.query(
    DbTables.studentSchoolHistory,
    where: '${StudentSchoolHistoryCols.studentId} = ?',
    whereArgs: [studentId],
  );

  final schoolHistoryEntries = <Sf10SchoolHistoryModel>[];

  for (final h in historyRows) {
    final historyId = h[CommonCols.id] as String;

    // Get previous subjects for this school history entry
    final prevSubjectRows = await db.query(
      DbTables.previousSchoolSubjects,
      where:
          '${PreviousSchoolSubjectsCols.schoolHistoryId} = ?',
      whereArgs: [historyId],
    );

    final prevSubjects = prevSubjectRows
        .map((s) => Sf10PreviousSubjectModel(
              subjectName:
                  s[PreviousSchoolSubjectsCols.subjectName] as String? ?? '',
              subjectGroup:
                  s[PreviousSchoolSubjectsCols.subjectGroup] as String?,
              q1Grade: s[PreviousSchoolSubjectsCols.q1Grade] as int?,
              q2Grade: s[PreviousSchoolSubjectsCols.q2Grade] as int?,
              q3Grade: s[PreviousSchoolSubjectsCols.q3Grade] as int?,
              q4Grade: s[PreviousSchoolSubjectsCols.q4Grade] as int?,
              finalGrade: s[PreviousSchoolSubjectsCols.finalGrade] as int?,
              descriptor:
                  s[PreviousSchoolSubjectsCols.descriptor] as String?,
            ))
        .toList();

    // Get previous attendance for this school history entry
    final prevAttendanceRows = await db.query(
      DbTables.previousSchoolAttendance,
      where:
          '${PreviousSchoolAttendanceCols.schoolHistoryId} = ?',
      whereArgs: [historyId],
    );

    final prevAttendance = prevAttendanceRows
        .map((a) => Sf10AttendanceMonthModel(
              month:
                  a[PreviousSchoolAttendanceCols.month] as String? ?? '',
              schoolDays:
                  a[PreviousSchoolAttendanceCols.schoolDays] as int? ?? 0,
              daysPresent:
                  a[PreviousSchoolAttendanceCols.daysPresent] as int? ?? 0,
              daysAbsent:
                  a[PreviousSchoolAttendanceCols.daysAbsent] as int? ?? 0,
            ))
        .toList();

    schoolHistoryEntries.add(Sf10SchoolHistoryModel(
      id: historyId,
      schoolName:
          h[StudentSchoolHistoryCols.schoolName] as String? ?? '',
      schoolId: h[StudentSchoolHistoryCols.schoolId] as String?,
      gradeLevel:
          h[StudentSchoolHistoryCols.gradeLevel] as String? ?? '',
      schoolYear:
          h[StudentSchoolHistoryCols.schoolYear] as String? ?? '',
      section: h[StudentSchoolHistoryCols.section] as String?,
      dateFrom: h[StudentSchoolHistoryCols.dateFrom] as String?,
      dateTo: h[StudentSchoolHistoryCols.dateTo] as String?,
      recordType:
          h[StudentSchoolHistoryCols.recordType] as String? ?? '',
      subjects: prevSubjects,
      attendance: prevAttendance,
    ));

    // Also build a scholastic record entry for this previous year
    final prevSubjectRowsForRecord = prevSubjectRows;
    final prevFinals = <int>[];
    final prevScholasticSubjects = <Sf10SubjectRowModel>[];

    for (final s in prevSubjectRowsForRecord) {
      final fg = s[PreviousSchoolSubjectsCols.finalGrade] as int?;
      if (fg != null) prevFinals.add(fg);

      prevScholasticSubjects.add(Sf10SubjectRowModel(
        classTitle:
            s[PreviousSchoolSubjectsCols.subjectName] as String? ?? '',
        subjectGroup:
            s[PreviousSchoolSubjectsCols.subjectGroup] as String?,
        periodGrades: [
          s[PreviousSchoolSubjectsCols.q1Grade] as int?,
          s[PreviousSchoolSubjectsCols.q2Grade] as int?,
          s[PreviousSchoolSubjectsCols.q3Grade] as int?,
          s[PreviousSchoolSubjectsCols.q4Grade] as int?,
        ],
        finalGrade: fg,
        descriptor: fg != null ? _getDescriptor(fg) : null,
      ));
    }

    final prevFinalAvg = computeAvg(prevFinals);
    final prevDescriptor =
        prevFinalAvg != null ? _getDescriptor(prevFinalAvg) : null;

    scholasticRecords.add(Sf10YearRecordModel(
      schoolYear: h[StudentSchoolHistoryCols.schoolYear] as String? ?? '',
      gradeLevel:
          h[StudentSchoolHistoryCols.gradeLevel] as String? ?? '',
      section: h[StudentSchoolHistoryCols.section] as String?,
      schoolName:
          h[StudentSchoolHistoryCols.schoolName] as String? ?? '',
      subjects: prevScholasticSubjects,
      finalAverage: prevFinalAvg,
      descriptor: prevDescriptor,
      attendance: prevAttendance,
    ));
  }

  return Sf10ResponseModel(
    studentId: studentId,
    studentName: studentName,
    lrn: learner?[LearnerDetailsCols.lrn] as String?,
    birthdate: learner?[LearnerDetailsCols.birthdate] as String?,
    birthplace: learner?[LearnerDetailsCols.birthplace] as String?,
    homeAddress: learner?[LearnerDetailsCols.homeAddress] as String?,
    sex: learner?[LearnerDetailsCols.sex] as String?,
    age: learner?[LearnerDetailsCols.age] as int?,
    fatherName: learner?[LearnerDetailsCols.fatherName] as String?,
    motherName: learner?[LearnerDetailsCols.motherName] as String?,
    guardianName: learner?[LearnerDetailsCols.guardianName] as String?,
    guardianContact:
        learner?[LearnerDetailsCols.guardianContact] as String?,
    trackStrand: learner?[LearnerDetailsCols.trackStrand] as String?,
    curriculum: learner?[LearnerDetailsCols.curriculum] as String?,
    currentSchoolYear: schoolYear,
    currentGradeLevel: gradeLevel,
    currentSection: section,
    schoolHistory: schoolHistoryEntries,
    scholasticRecords: scholasticRecords,
  );
}
