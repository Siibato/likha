import 'dart:io';

import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';

Future<void> clearAllUserData({
  required ClassLocalDataSource classLocalDataSource,
  required AssignmentLocalDataSource assignmentLocalDataSource,
  required AssessmentLocalDataSource assessmentLocalDataSource,
  required LearningMaterialLocalDataSource learningMaterialLocalDataSource,
  required GradingLocalDataSource gradingLocalDataSource,
  required AuthLocalDataSource localDataSource,
  required SyncQueue syncQueue,
  required StorageService storageService,
  TosLocalDataSource? tosLocalDataSource,
  StudentRecordsLocalDataSource? studentRecordsLocalDataSource,
  bool clearSyncQueue = true,
}) async {
  try {
    await storageService.setLogoutInProgress();
    final storageFuture = storageService.clearAuthData();

    await classLocalDataSource.localDatabase.clearAllDataIncrementally();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/submission_file_cache');
      if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
    } catch (_) {}

    await storageFuture;
    await storageService.clearLogoutInProgress();
  } catch (_) {
    await storageService.clearLogoutInProgress();
  }
}

Future<List<UserModel>> buildPendingAccounts(SyncQueue syncQueue) async {
  // Get all admin user creations (pending OR failed) to prevent queueing duplicates
  final entries = await syncQueue.getByEntityAndOperation(
    SyncEntityType.adminUser,
    SyncOperation.create,
  );
  final seenUsernames = <String>{};
  final result = <UserModel>[];
  for (final entry in entries) {
    final username = entry.payload['username'] as String? ?? '';
    if (seenUsernames.contains(username)) {
      continue;
    }
    seenUsernames.add(username);
    // Read id from payload; support both old 'local_id' and new 'id' field for backward compat
    final localId = (entry.payload['id'] ?? entry.payload['local_id']) as String? ?? '';
    result.add(UserModel(
      id: localId,
      username: username,
      firstName: entry.payload['first_name'] as String? ?? '',
      lastName: entry.payload['last_name'] as String? ?? '',
      role: entry.payload['role'] as String? ?? '',
      accountStatus: 'pending_activation',
      isActive: false,
      activatedAt: null,
      createdAt: DateTime.now(),
    ));
  }
  return result;
}
