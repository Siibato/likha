import 'package:equatable/equatable.dart';
import 'package:likha/core/sync/sync_queue.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final String accountStatus;
  final bool isActive;
  final DateTime? activatedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? cachedAt;
  final SyncStatus syncStatus;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.accountStatus,
    required this.isActive,
    this.activatedAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.cachedAt,
    this.syncStatus = SyncStatus.synced,
  });

  String get fullName => '$lastName, $firstName'.trim();

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
  bool get isAdmin => role == 'admin';
  bool get isPendingActivation => accountStatus == 'pending_activation';
  bool get isActivated => accountStatus == 'activated' || accountStatus == 'active';
  bool get isLocked => accountStatus == 'locked';

  @override
  List<Object?> get props => [
    id,
    username,
    firstName,
    lastName,
    role,
    accountStatus,
    isActive,
    activatedAt,
    createdAt,
    updatedAt,
    deletedAt,
    cachedAt,
    syncStatus,
  ];
}
