import 'package:likha/core/utils/typedef.dart';

abstract class DocumentExportRepository {
  ResultFuture<List<int>> exportClassGradesPdf({
    required String classId,
    required int termNumber,
  });

  ResultFuture<List<int>> exportClassGradesExcel({
    required String classId,
    required int termNumber,
  });

  ResultFuture<List<int>> exportSf9Pdf({
    required String classId,
    required String studentId,
  });

  ResultFuture<List<int>> exportSf10Pdf({
    required String classId,
    required String studentId,
  });

  ResultFuture<List<int>> exportSf10Excel({
    required String classId,
    required String studentId,
  });
}
