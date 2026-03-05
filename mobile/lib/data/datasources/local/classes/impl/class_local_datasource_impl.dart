import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import '../class_local_datasource_base.dart';
import 'class_cache_mixin.dart';
import 'class_enrollment_mixin.dart';
import 'class_mutation_mixin.dart';
import 'class_query_mixin.dart';
import 'class_student_search_mixin.dart';

class ClassLocalDataSourceImpl extends ClassLocalDataSourceBase
    with
        ClassQueryMixin,
        ClassCacheMixin,
        ClassMutationMixin,
        ClassEnrollmentMixin,
        ClassStudentSearchMixin {
  @override
  final LocalDatabase localDatabase;

  @override
  final SyncQueue syncQueue;

  ClassLocalDataSourceImpl(this.localDatabase, this.syncQueue);
}

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.id,
    required super.student,
    required super.joinedAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    // Accept both new field name (joined_at) and old field name (enrolled_at) for backward compat
    final joinedAtStr = (json['joined_at'] ?? json['enrolled_at']) as String?;
    if (joinedAtStr == null) {
      throw ArgumentError('Missing joined_at or enrolled_at field');
    }

    return EnrollmentModel(
      id: json['id'] as String,
      student: UserModel.fromJson(json['student'] as Map<String, dynamic>),
      joinedAt: DateTime.parse(joinedAtStr),
    );
  }
}