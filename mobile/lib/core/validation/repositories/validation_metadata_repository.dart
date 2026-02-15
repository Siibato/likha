import 'package:likha/core/validation/models/validation_metadata.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:sqflite/sqflite.dart';

abstract class ValidationMetadataRepository {
  Future<ValidationMetadata?> getMetadata(String entityType);
  Future<void> updateValidationTime(String entityType, ValidationMetadata metadata);
  Future<void> deleteMetadata(String entityType);
}

class ValidationMetadataRepositoryImpl implements ValidationMetadataRepository {
  final LocalDatabase _localDatabase;

  ValidationMetadataRepositoryImpl(this._localDatabase);

  @override
  Future<ValidationMetadata?> getMetadata(String entityType) async {
    try {
      final db = await _localDatabase.database;
      final result = await db.query(
        'validation_metadata',
        where: 'entity_type = ?',
        whereArgs: [entityType],
      );

      if (result.isEmpty) {
        return null;
      }

      return ValidationMetadata.fromJson(
        Map<String, dynamic>.from(result.first),
      );
    } catch (e) {
      throw CacheException('Failed to get validation metadata: $e');
    }
  }

  @override
  Future<void> updateValidationTime(
    String entityType,
    ValidationMetadata metadata,
  ) async {
    try {
      final db = await _localDatabase.database;
      await db.insert(
        'validation_metadata',
        metadata.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to update validation metadata: $e');
    }
  }

  @override
  Future<void> deleteMetadata(String entityType) async {
    try {
      final db = await _localDatabase.database;
      await db.delete(
        'validation_metadata',
        where: 'entity_type = ?',
        whereArgs: [entityType],
      );
    } catch (e) {
      throw CacheException('Failed to delete validation metadata: $e');
    }
  }
}
