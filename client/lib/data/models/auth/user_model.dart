import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.firstName,
    required super.lastName,
    required super.role,
    required super.accountStatus,
    required super.isActive,
    super.activatedAt,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.cachedAt,
    super.syncStatus = SyncStatus.synced,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final accountStatus = json['account_status'] as String;
    // Compute isActive: not locked, not deactivated
    final isActive = accountStatus != 'locked' && accountStatus != 'deactivated';

    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
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
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
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
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.dbValue == (map['sync_status'] as String?),
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'account_status': accountStatus,
      'activated_at': activatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toPayload() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'account_status': accountStatus,
      'activated_at': activatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'sync_status': syncStatus.dbValue,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? role,
    String? accountStatus,
    bool? isActive,
    DateTime? activatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    SyncStatus? syncStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      isActive: isActive ?? this.isActive,
      activatedAt: activatedAt ?? this.activatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
