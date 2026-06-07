import 'package:sqflite/sqflite.dart';

import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

Future<void> cacheMaterialFilesOp(
  LocalDatabase localDatabase,
  String materialId,
  List<MaterialFile> files,
) async {
  try {
    CacheLogger.instance.log('Starting cacheMaterialFiles with ${files.length} files for materialId=$materialId');
    final db = await localDatabase.database;
    for (final file in files) {
      // Preserve local cache state if row already exists
      final existing = await db.query(
        'material_files',
        columns: ['local_path'],
        where: 'id = ?',
        whereArgs: [file.id],
      );

      if (existing.isEmpty) {
        CacheLogger.instance.log('Inserting new file: ${file.fileName} (${file.id})');
        final rowsAffected = await db.insert(
          'material_files',
          {
            'id': file.id,
            'material_id': materialId,
            'file_name': file.fileName,
            'file_type': file.fileType,
            'file_size': file.fileSize,
            'uploaded_at': file.uploadedAt.toIso8601String(),
            'local_path': '',
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        CacheLogger.instance.log('Insert completed, rowsAffected=$rowsAffected');
      } else {
        CacheLogger.instance.log('Updating existing file: ${file.fileName} (${file.id})');
        // Only update server-side metadata — preserve local_path
        final rowsAffected = await db.update(
          'material_files',
          {
            'file_name': file.fileName,
            'file_type': file.fileType,
            'file_size': file.fileSize,
            'uploaded_at': file.uploadedAt.toIso8601String(),
            'cached_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [file.id],
        );
        CacheLogger.instance.log('Update completed, rowsAffected=$rowsAffected');
      }
    }
    // Remove stale rows for this material that are no longer in the fresh list.
    // Use soft-delete when the server returns an empty list — an empty response may
    // indicate a fetch error rather than a genuine "no files" state, so a hard delete
    // here would be unrecoverable.
    if (files.isEmpty) {
      await db.update(
        'material_files',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'material_id = ? AND deleted_at IS NULL',
        whereArgs: [materialId],
      );
    } else {
      final freshIds = files.map((f) => f.id).toList();
      final placeholders = freshIds.map((_) => '?').join(', ');
      await db.rawDelete(
        'DELETE FROM material_files WHERE material_id = ? AND id NOT IN ($placeholders)',
        [materialId, ...freshIds],
      );
    }

    CacheLogger.instance.log('cacheMaterialFiles completed successfully');
  } catch (e) {
    CacheLogger.instance.error('Error in cacheMaterialFiles', e);
    throw CacheException('Failed to cache material files: $e');
  }
}
