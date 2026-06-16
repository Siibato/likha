import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';
import 'operations/classes.dart' as ops;

class ClassRepositoryImpl implements ClassRepository {
  final ClassRemoteDataSource _remoteDataSource;
  final ClassLocalDataSource _localDataSource;
  final SyncQueue _syncQueue;
  final DataEventBus _dataEventBus;

  ClassRepositoryImpl({
    required ClassRemoteDataSource remoteDataSource,
    required ClassLocalDataSource localDataSource,
    required SyncQueue syncQueue,
    required DataEventBus dataEventBus,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncQueue = syncQueue,
        _dataEventBus = dataEventBus;

  @override
  ResultFuture<MutationResult<ClassEntity>> createClass({
    required String title,
    String? description,
    String? teacherId,
    String? teacherUsername,
    String? teacherFullName,
    bool isAdvisory = false,
  }) =>
      ops.createClass(
        _localDataSource,
        _syncQueue,
        title: title,
        description: description,
        teacherId: teacherId,
        teacherUsername: teacherUsername,
        teacherFullName: teacherFullName,
        isAdvisory: isAdvisory,
      );

  @override
  ResultVoid deleteClass({required String classId}) =>
      ops.deleteClass(
        _localDataSource,
        _syncQueue,
        classId: classId,
      );

  @override
  ResultFuture<MutationResult<ClassEntity>> updateClass({
    required String classId,
    String? title,
    String? description,
    String? teacherId,
    bool? isAdvisory,
  }) =>
      ops.updateClass(
        _localDataSource,
        _syncQueue,
        classId: classId,
        title: title,
        description: description,
        teacherId: teacherId,
        isAdvisory: isAdvisory,
      );

  @override
  ResultFuture<List<ClassEntity>> getAllClasses({bool skipBackgroundRefresh = false}) =>
      ops.getAllClasses(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<List<ClassEntity>> getMyClasses({bool skipBackgroundRefresh = false}) =>
      ops.getMyClasses(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<ClassDetail> getClassDetail({required String classId}) =>
      ops.getClassDetail(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
      );

  @override
  ResultFuture<MutationResult<Participant>> addStudent({
    required String classId,
    required String studentId,
  }) =>
      ops.addStudent(
        _localDataSource,
        _syncQueue,
        classId: classId,
        studentId: studentId,
      );

  @override
  ResultVoid removeStudent({
    required String classId,
    required String studentId,
  }) =>
      ops.removeStudent(
        _localDataSource,
        _syncQueue,
        classId: classId,
        studentId: studentId,
      );

  @override
  ResultFuture<List<User>> searchStudents({String? query, bool skipBackgroundRefresh = false}) =>
      ops.searchStudents(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        query: query,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );

  @override
  ResultFuture<List<User>> getParticipants({required String classId, bool skipBackgroundRefresh = false}) =>
      ops.getParticipants(
        _localDataSource,
        _remoteDataSource,
        _dataEventBus,
        classId: classId,
        skipBackgroundRefresh: skipBackgroundRefresh,
      );
}