import 'package:equatable/equatable.dart';
import 'package:likha/core/sync/sync_queue.dart';

class ClassEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final String teacherUsername;
  final String teacherFullName;
  final bool isArchived;
  final bool isAdvisory;
  final int studentCount;
  final String? termType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cachedAt;
  final SyncStatus syncStatus;

  const ClassEntity({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.teacherUsername,
    required this.teacherFullName,
    required this.isArchived,
    this.isAdvisory = false,
    required this.studentCount,
    this.termType,
    required this.createdAt,
    required this.updatedAt,
    this.cachedAt,
    this.syncStatus = SyncStatus.synced,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    teacherId,
    teacherUsername,
    teacherFullName,
    isArchived,
    isAdvisory,
    studentCount,
    termType,
    createdAt,
    updatedAt,
    cachedAt,
    syncStatus,
  ];
}
