import 'package:likha/data/models/grading/period_grade_model.dart';
import '../grading_local_datasource_base.dart';
import 'operations/period_grade/get_period_grades_by_class.dart';
import 'operations/period_grade/get_student_all_periods.dart';
import 'operations/period_grade/save_period_grades.dart';
import 'operations/period_grade/update_transmuted_grade.dart';

mixin GradingPeriodMixin on GradingLocalDataSourceBase {
  @override
  Future<List<PeriodGradeModel>> getPeriodGradesByClass(
    String classId,
    int gradingPeriodNumber,
  ) async {
    return getPeriodGradesByClassOp(localDatabase, classId, gradingPeriodNumber);
  }

  @override
  Future<List<PeriodGradeModel>> getStudentAllPeriods(
    String classId,
    String studentId,
  ) async {
    return getStudentAllPeriodsOp(localDatabase, classId, studentId);
  }

  @override
  Future<void> savePeriodGrades(List<PeriodGradeModel> grades) async {
    return savePeriodGradesOp(localDatabase, grades);
  }

  @override
  Future<void> updateTransmutedGrade(
    String classId,
    String studentId,
    int gradingPeriodNumber,
    int transmutedGrade,
  ) async {
    return updateTransmutedGradeOp(localDatabase, syncQueue, classId, studentId, gradingPeriodNumber, transmutedGrade);
  }
}
