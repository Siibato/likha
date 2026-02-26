import 'package:likha/domain/auth/entities/activity_log.dart';

class ActivityLogModel extends ActivityLog {
  const ActivityLogModel({
    required super.id,
    required super.userId,
    required super.action,
    super.performedBy,
    super.details,
    required super.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      performedBy: json['performed_by'] as String?,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
