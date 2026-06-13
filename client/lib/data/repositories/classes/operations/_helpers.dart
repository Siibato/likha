import 'dart:async';

import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/services/storage_service.dart';

Future<void>? _allClassesBackgroundFetch;

Future<String?> getCurrentUserId() async {
  try {
    return await sl<StorageService>().getUserId();
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
      if (classesHaveChanged(cached, fresh)) {
        await localDataSource.cacheClasses(fresh);
        dataEventBus.notifyClassesChanged();
      }
    } catch (_) {} finally {
      _allClassesBackgroundFetch = null;
    }
  });
}

bool classesHaveChanged(List<ClassEntity> local, List<ClassEntity> remote) {
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
