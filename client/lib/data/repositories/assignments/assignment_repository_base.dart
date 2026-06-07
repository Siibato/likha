import 'dart:io';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/services/storage_service.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

abstract class AssignmentRepositoryBase extends AssignmentRepository {
  final AssignmentRemoteDataSource remoteDataSource;
  final AssignmentLocalDataSource localDataSource;
  final ValidationService validationService;
  final ConnectivityService connectivityService;
  final SyncQueue syncQueue;
  final ServerReachabilityService serverReachabilityService;
  final StorageService storageService;
  final DataEventBus dataEventBus;

  AssignmentRepositoryBase({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.validationService,
    required this.connectivityService,
    required this.syncQueue,
    required this.serverReachabilityService,
    required this.storageService,
    required this.dataEventBus,
  });

  // Shared helpers used by AssignmentSubmissionMixin
  String mimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  Future<int> fileSize(String filePath) async {
    try {
      return await File(filePath).length();
    } catch (_) {
      return 0;
    }
  }
}