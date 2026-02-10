import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  final String id;
  final String userId;
  final String action;
  final String? performedBy;
  final String? details;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.action,
    this.performedBy,
    this.details,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, action, performedBy, details, createdAt];
}
