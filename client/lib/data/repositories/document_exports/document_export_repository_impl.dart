import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/document_exports/document_export_remote_datasource.dart';
import 'package:likha/domain/document_exports/repositories/document_export_repository.dart';

class DocumentExportRepositoryImpl implements DocumentExportRepository {
  final DocumentExportRemoteDataSource _remoteDataSource;

  DocumentExportRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<List<int>> exportClassGradesPdf({
    required String classId,
    required int termNumber,
  }) async {
    try {
      final bytes = await _remoteDataSource.exportClassGradesPdf(
        classId: classId,
        termNumber: termNumber,
      );
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<int>> exportClassGradesExcel({
    required String classId,
    required int termNumber,
  }) async {
    try {
      final bytes = await _remoteDataSource.exportClassGradesExcel(
        classId: classId,
        termNumber: termNumber,
      );
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<int>> exportSf9Pdf({
    required String classId,
    required String studentId,
  }) async {
    try {
      final bytes = await _remoteDataSource.exportSf9Pdf(
        classId: classId,
        studentId: studentId,
      );
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<int>> exportSf10Pdf({
    required String classId,
    required String studentId,
  }) async {
    try {
      final bytes = await _remoteDataSource.exportSf10Pdf(
        classId: classId,
        studentId: studentId,
      );
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<int>> exportSf10Excel({
    required String classId,
    required String studentId,
  }) async {
    try {
      final bytes = await _remoteDataSource.exportSf10Excel(
        classId: classId,
        studentId: studentId,
      );
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<int>> exportTosExcel({
    required String tosId,
  }) async {
    try {
      final bytes = await _remoteDataSource.exportTosExcel(tosId: tosId);
      return Right(bytes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
