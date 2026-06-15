import 'package:likha/core/logging/app_logger.dart';

/// Logger for repository and remote datasource operations.
class RepoLogger extends AppLogger {
  static final RepoLogger instance = RepoLogger._();

  RepoLogger._() : super(tag: '[REPO]', envKey: 'REPO_LOGGING_ENABLED');
}
