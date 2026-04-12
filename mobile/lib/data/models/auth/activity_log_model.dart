import 'package:likha/domain/auth/entities/activity_log.dart';

class ActivityLogModel extends ActivityLog {
  final DateTime? cachedAt;
  final bool needsSync;

  const ActivityLogModel({
    required super.id,
    required super.userId,
    required super.action,
    super.details,
    required super.createdAt,
    this.cachedAt,
    this.needsSync = false,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      action: map['action'] as String,
      details: map['details'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      cachedAt: map['cached_at'] != null
          ? DateTime.parse(map['cached_at'] as String)
          : null,
      needsSync: (map['needs_sync'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'cached_at': cachedAt?.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
