import 'package:likha/domain/auth/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.fullName,
    required super.role,
    required super.accountStatus,
    required super.isActive,
    super.activatedAt,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.cachedAt,
    super.needsSync = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final accountStatus = json['account_status'] as String;
    // Compute isActive: not locked, not deactivated
    final isActive = accountStatus != 'locked' && accountStatus != 'deactivated';

    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      accountStatus: accountStatus,
      isActive: isActive,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final accountStatus = map['account_status'] as String?;
    // Compute isActive: not locked, not deactivated
    final isActive = accountStatus != null &&
        accountStatus != 'locked' &&
        accountStatus != 'deactivated';

    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      accountStatus: accountStatus ?? 'pending_activation',
      isActive: isActive,
      activatedAt: map['activated_at'] != null
          ? DateTime.parse(map['activated_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'account_status': accountStatus,
      'activated_at': activatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'account_status': accountStatus,
      'activated_at': activatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? role,
    String? accountStatus,
    bool? isActive,
    DateTime? activatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    bool? needsSync,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      isActive: isActive ?? this.isActive,
      activatedAt: activatedAt ?? this.activatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }
}
