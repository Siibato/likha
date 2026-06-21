import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/grading/general_average_model.dart';

Future<GeneralAverageResponseModel?> assembleGeneralAveragesLocal(
  LocalDatabase localDatabase,
  String classId,
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
  if (schoolYear == null) return null;

  // 2. Get all enrolled students for this advisory class
  final studentRows = await db.rawQuery('''
    SELECT u.${CommonCols.id}, u.${UsersCols.firstName}, u.${UsersCols.lastName}
    FROM ${DbTables.classParticipants} cp
    JOIN ${DbTables.users} u ON u.${CommonCols.id} = cp.${ClassParticipantsCols.userId}
    WHERE cp.${ClassParticipantsCols.classId} = ? AND cp.${ClassParticipantsCols.removedAt} IS NULL
    ORDER BY u.${UsersCols.lastName}, u.${UsersCols.firstName}
  ''', [classId]);

  if (studentRows.isEmpty) return null;

  final students = <StudentGeneralAverageModel>[];

  for (final studentRow in studentRows) {
    final studentId = studentRow[CommonCols.id] as String;
    final studentName = '${studentRow[UsersCols.lastName] ?? ''}, ${studentRow[UsersCols.firstName] ?? ''}'.trim();
    final studentNameStr = studentName.isEmpty ? 'Unknown Student' : studentName;

    // 3. Get all class_participants for this student (not removed)
    final participantRows = await db.query(
      DbTables.classParticipants,
      columns: [ClassParticipantsCols.classId],
      where:
          '${ClassParticipantsCols.userId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
      whereArgs: [studentId],
    );

    if (participantRows.isEmpty) {
      students.add(StudentGeneralAverageModel(
        studentId: studentId,
        studentName: studentNameStr,
        generalAverage: null,
        subjectCount: 0,
        subjects: const [],
      ));
      continue;
    }

    final enrolledClassIds = participantRows
        .map((r) => r[ClassParticipantsCols.classId] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toList()
        .cast<String>();

    // 4. Filter class IDs by matching school_year
    final classIdPlaceholders = enrolledClassIds.map((_) => '?').join(', ');
    final classMatches = await db.rawQuery(
      'SELECT ${CommonCols.id}, ${ClassesCols.title} FROM ${DbTables.classes} '
      'WHERE ${CommonCols.id} IN ($classIdPlaceholders) '
      'AND ${ClassesCols.schoolYear} = ? '
      'AND ${CommonCols.deletedAt} IS NULL',
      [...enrolledClassIds, schoolYear],
    );

    final subjects = <SubjectGradeModel>[];
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

      final transmuted = pgRows
          .map((pg) => pg[TermGradesCols.transmutedGrade] as int?)
          .whereType<int>()
          .toList();

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

      subjects.add(SubjectGradeModel(
        classId: cid,
        classTitle: ctitle,
        finalGrade: finalGrade,
      ));
    }

    // 5. Compute general average
    int? computeAvg(List<int> grades) {
      if (grades.isEmpty) return null;
      final avg = grades.reduce((a, b) => a + b) / grades.length;
      return avg.round();
    }

    final generalAverage = computeAvg(finalGrades);

    students.add(StudentGeneralAverageModel(
      studentId: studentId,
      studentName: studentName,
      generalAverage: generalAverage,
      subjectCount: subjects.length,
      subjects: subjects,
    ));
  }

  return GeneralAverageResponseModel(
    classId: classId,
    students: students,
  );
}
