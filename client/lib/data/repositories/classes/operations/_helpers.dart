import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/services/storage_service.dart';

Future<String?> getCurrentUserId() async {
  try {
    return await sl<StorageService>().getUserId();
  } catch (e) {
    return null;
  }
}

Future<String?> getCurrentUserRole() async {
  try {
    return await sl<StorageService>().getUserRole();
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

bool classDetailHasChanged(ClassDetail local, ClassDetail remote) {
  // Only trust remote data when it is strictly newer than local.
  // If local is newer or the same age, local mutations take precedence.
  return remote.updatedAt.isAfter(local.updatedAt);
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
