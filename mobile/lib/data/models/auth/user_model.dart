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
    super.deletedAt,
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
      accountStatus: accountStatus ?? 'active',
      isActive: isActive,
      activatedAt: map['activated_at'] != null
          ? DateTime.parse(map['activated_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
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
      'updated_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
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
    );
  }
}
