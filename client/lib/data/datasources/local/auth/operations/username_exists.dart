import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

/// Checks whether a username already exists in the local database.
/// Compares case-insensitively and ignores soft-deleted rows.
Future<bool> usernameExists(
  LocalDatabase localDatabase,
  String username,
) async {
  final db = await localDatabase.database;
  final results = await db.query(
    DbTables.users,
    columns: [CommonCols.id],
    where: 'LOWER(${UsersCols.username}) = ? AND ${CommonCols.deletedAt} IS NULL',
    whereArgs: [username.toLowerCase()],
    limit: 1,
  );
  return results.isNotEmpty;
}
