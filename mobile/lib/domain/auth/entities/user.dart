import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String accountStatus;
  final bool isActive;
  final DateTime? activatedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? cachedAt;
  final bool needsSync;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.accountStatus,
    required this.isActive,
    this.activatedAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.cachedAt,
    this.needsSync = false,
  });

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
  bool get isAdmin => role == 'admin';
  bool get isPendingActivation => accountStatus == 'pending_activation';
  bool get isActivated => accountStatus == 'activated';
  bool get isLocked => accountStatus == 'locked';

  @override
  List<Object?> get props => [
    id,
    username,
    fullName,
    role,
    accountStatus,
    isActive,
    activatedAt,
    createdAt,
    updatedAt,
    deletedAt,
    cachedAt,
    needsSync,
  ];
}
