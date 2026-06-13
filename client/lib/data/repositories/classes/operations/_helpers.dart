import 'dart:async';

import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/services/storage_service.dart';

Future<void>? _myClassesBackgroundFetch;
Future<void>? _allClassesBackgroundFetch;

Future<String?> getCurrentUserId(StorageService storageService) async {
  try {
    return await storageService.getUserId();
  } catch (e) {
    return null;
  }
}

Future<void> syncInBackgroundForClass(
  ClassRemoteDataSource remoteDataSource,
  ClassLocalDataSource localDataSource,
  String classId,
) async {
  try {
    final remoteClass = await remoteDataSource.getClassDetail(classId: classId);
    await localDataSource.cacheClassDetail(remoteClass);
  } catch (_) {
    // Best-effort
  }
}

void backgroundFetchAllClasses(
  ClassRemoteDataSource remoteDataSource,
  ClassLocalDataSource localDataSource,
  DataEventBus dataEventBus,
) {
  if (_allClassesBackgroundFetch != null) return;
  _allClassesBackgroundFetch = Future.microtask(() async {
    try {
      final fresh = await remoteDataSource.getAllClasses();
      final List<ClassEntity> cached;
      try {
        cached = await localDataSource.getCachedClasses();
      } on CacheException {
        await localDataSource.cacheClasses(fresh);
        dataEventBus.notifyClassesChanged();
        return;
      }
      if (_classesHaveChanged(cached, fresh)) {
        await localDataSource.cacheClasses(fresh);
        dataEventBus.notifyClassesChanged();
      }
    } catch (_) {} finally {
      _allClassesBackgroundFetch = null;
    }
  });
}

void backgroundFetchMyClasses(
  ClassRemoteDataSource remoteDataSource,
  ClassLocalDataSource localDataSource,
  DataEventBus dataEventBus,
  StorageService storageService,
) {
  if (_myClassesBackgroundFetch != null) return;
  _myClassesBackgroundFetch = Future.microtask(() async {
    try {
      final fresh = await remoteDataSource.getMyClasses();
      final currentUserId = await getCurrentUserId(storageService);
      if (currentUserId == null) return;
      final List<ClassEntity> cached;
      try {
        cached = await localDataSource.getCachedClassesForUser(currentUserId);
      } on CacheException {
        await localDataSource.cacheClasses(fresh);
        await cacheStudentParticipations(localDataSource, fresh, currentUserId);
        dataEventBus.notifyClassesChanged();
        return;
      }
      if (_classesHaveChanged(cached, fresh)) {
        await localDataSource.cacheClasses(fresh);
        await cacheStudentParticipations(localDataSource, fresh, currentUserId);
        dataEventBus.notifyClassesChanged();
      }
    } catch (_) {} finally {
      _myClassesBackgroundFetch = null;
    }
  });
}

bool _classesHaveChanged(List<ClassEntity> local, List<ClassEntity> remote) {
  if (local.length != remote.length) return true;
  final localById = {for (final c in local) c.id: c};
  for (final r in remote) {
    final l = localById[r.id];
    if (l == null) return true;
    if (l.updatedAt.isBefore(r.updatedAt)) return true;
    if (l.isAdvisory != r.isAdvisory) return true;
  }
  return false;
}

Future<void> cacheStudentParticipations(
  ClassLocalDataSource localDataSource,
  List<ClassEntity> classes,
  String userId,
) async {
  for (final cls in classes) {
    try {
      await localDataSource.cacheStudentParticipation(
        classId: cls.id,
        userId: userId,
        joinedAt: cls.createdAt,
      );
    } catch (_) {}
  }
}
