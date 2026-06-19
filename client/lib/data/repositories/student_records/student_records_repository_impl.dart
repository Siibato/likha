import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/entities/attendance_record.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/entities/previous_attendance.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class StudentRecordsRepositoryImpl implements StudentRecordsRepository {
  final StudentRecordsRemoteDataSource _remoteDataSource;

  StudentRecordsRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<LearnerDetails?> getLearnerDetails({required String classId, required String studentId}) async {
    try {
      final model = await _remoteDataSource.getLearnerDetails(classId: classId, studentId: studentId);
      return Right(model);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return const Right(null);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<LearnerDetails> upsertLearnerDetails({required String classId, required String studentId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.upsertLearnerDetails(classId: classId, studentId: studentId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<AttendanceRecord>> getAttendance({required String classId, required String studentId, String? schoolYear}) async {
    try {
      final models = await _remoteDataSource.getAttendance(classId: classId, studentId: studentId, schoolYear: schoolYear);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<AttendanceRecord> upsertAttendance({required String classId, required String studentId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.upsertAttendance(classId: classId, studentId: studentId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<CoreValuesRecord>> getCoreValues({required String classId, required String studentId, String? schoolYear}) async {
    try {
      final models = await _remoteDataSource.getCoreValues(classId: classId, studentId: studentId, schoolYear: schoolYear);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<CoreValuesRecord> upsertCoreValues({required String classId, required String studentId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.upsertCoreValues(classId: classId, studentId: studentId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<SchoolHistory>> getSchoolHistory({required String classId, required String studentId}) async {
    try {
      final models = await _remoteDataSource.getSchoolHistory(classId: classId, studentId: studentId);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SchoolHistory> createSchoolHistory({required String classId, required String studentId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.createSchoolHistory(classId: classId, studentId: studentId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SchoolHistory> updateSchoolHistory({required String classId, required String studentId, required String historyId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.updateSchoolHistory(classId: classId, studentId: studentId, historyId: historyId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> deleteSchoolHistory({required String classId, required String studentId, required String historyId}) async {
    try {
      await _remoteDataSource.deleteSchoolHistory(classId: classId, studentId: studentId, historyId: historyId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<PreviousSubject>> getPreviousSubjects({required String classId, required String studentId, String? schoolHistoryId}) async {
    try {
      final models = await _remoteDataSource.getPreviousSubjects(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<PreviousSubject> upsertPreviousSubject({required String classId, required String studentId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.upsertPreviousSubject(classId: classId, studentId: studentId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<PreviousAttendance>> getPreviousAttendance({required String classId, required String studentId, String? schoolHistoryId}) async {
    try {
      final models = await _remoteDataSource.getPreviousAttendance(classId: classId, studentId: studentId, schoolHistoryId: schoolHistoryId);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<PreviousAttendance> upsertPreviousAttendance({required String classId, required String studentId, required Map<String, dynamic> data}) async {
    try {
      final model = await _remoteDataSource.upsertPreviousAttendance(classId: classId, studentId: studentId, data: data);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Sf10Response> getSf10({required String classId, required String studentId}) async {
    try {
      final model = await _remoteDataSource.getSf10(classId: classId, studentId: studentId);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
