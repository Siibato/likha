import 'package:likha/data/repositories/auth/auth_repository_base.dart';
import 'mixins/auth_login_mixin.dart';
import 'mixins/auth_admin_mixin.dart';
import 'mixins/auth_activity_log_mixin.dart';

class AuthRepositoryImpl extends AuthRepositoryBase
    with
        AuthLoginMixin,
        AuthAdminMixin,
        AuthActivityLogMixin {
  AuthRepositoryImpl({
    required super.remoteDataSource,
    required super.localDataSource,
    required super.serverReachabilityService,
    required super.storageService,
    required super.syncQueue,
    required super.localDatabase,
    required super.classLocalDataSource,
    required super.assignmentLocalDataSource,
    required super.assessmentLocalDataSource,
    required super.learningMaterialLocalDataSource,
  });
}