import 'package:likha/core/database/local_database.dart';
import 'auth_local_datasource.dart';

abstract class AuthLocalDataSourceBase implements AuthLocalDataSource {
  LocalDatabase get localDatabase;
}