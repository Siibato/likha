import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/data/models/user_model.dart';
import 'package:likha/domain/classes/data/models/class_detail_model.dart';
import 'package:likha/domain/classes/data/models/class_model.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract class ClassLocalDataSource {
  Future<List<ClassModel>> getCachedClasses();
  Future<ClassDetailModel> getCachedClassDetail(String classId);
  Future<void> cacheClasses(List<ClassModel> classes);
  Future<void> cacheClassDetail(ClassDetailModel classDetail);
  Future<ClassModel> createClassLocally({
    required String title,
    required String description,
    required String teacherId,
    required String teacherUsername,
    required String teacherFullName,
  });
  Future<void> updateClassLocally({
    required String classId,
    required String title,
    required String description,
  });
  Future<void> addStudentLocally({
    required String classId,
    required UserModel student,
  });
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  });
  Future<void> clearAllCache();
}

class ClassLocalDataSourceImpl implements ClassLocalDataSource {
  final LocalDatabase _localDatabase;
  final SyncQueue _syncQueue;

  ClassLocalDataSourceImpl(this._localDatabase, this._syncQueue);

  @override
  Future<List<ClassModel>> getCachedClasses() async {
    try {
      final db = await _localDatabase.database;
      final results = await db.query('classes', orderBy: 'title ASC');

      if (results.isEmpty) {
        throw CacheException('No cached classes found');
      }

      return results.map(ClassModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ClassDetailModel> getCachedClassDetail(String classId) async {
    try {
      final db = await _localDatabase.database;
      final classResult = await db.query(
        'classes',
        where: 'id = ?',
        whereArgs: [classId],
      );

      if (classResult.isEmpty) {
        throw CacheException('Class $classId not cached');
      }

      final classMap = classResult.first;
      final enrollmentResults = await db.query(
        'class_enrollments',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'username ASC',
      );

      final students = enrollmentResults
          .map((e) => EnrollmentModel(
                id: e['id'] as String,
                student: UserModel(
                  id: e['student_id'] as String,
                  username: e['username'] as String,
                  fullName: e['full_name'] as String,
                  role: e['role'] as String,
                  accountStatus: e['account_status'] as String,
                  isActive: (e['is_active'] as int?) == 1,
                  createdAt: DateTime.parse(e['enrolled_at'] as String),
                ),
                enrolledAt: DateTime.parse(e['enrolled_at'] as String),
              ))
          .toList();

      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String,
        isArchived: (classMap['is_archived'] as int?) == 1,
        students: students,
        createdAt: DateTime.parse(classMap['created_at'] as String),
        updatedAt: DateTime.parse(classMap['updated_at'] as String),
      );
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheClasses(List<ClassModel> classes) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        for (final classModel in classes) {
          final map = classModel.toMap();
          map['cached_at'] = DateTime.now().toIso8601String();
          map['sync_status'] = 'synced';
          map['is_dirty'] = 0;

          await txn.insert(
            'classes',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache classes: $e');
    }
  }

  @override
  Future<void> cacheClassDetail(ClassDetailModel classDetail) async {
    try {
      final db = await _localDatabase.database;
      await db.transaction((txn) async {
        // Cache the class itself
        final classMap = ClassModel(
          id: classDetail.id,
          title: classDetail.title,
          description: classDetail.description,
          teacherId: classDetail.teacherId,
          teacherUsername: '', // Not available in detail
          teacherFullName: '', // Not available in detail
          isArchived: classDetail.isArchived,
          studentCount: classDetail.students.length,
          createdAt: classDetail.createdAt,
          updatedAt: classDetail.updatedAt,
        ).toMap();

        classMap['cached_at'] = DateTime.now().toIso8601String();
        classMap['sync_status'] = 'synced';
        classMap['is_dirty'] = 0;

        await txn.insert(
          'classes',
          classMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Cache enrollments
        for (final enrollment in classDetail.students) {
          await txn.insert(
            'class_enrollments',
            {
              'id': enrollment.id,
              'class_id': classDetail.id,
              'student_id': enrollment.student.id,
              'username': enrollment.student.username,
              'full_name': enrollment.student.fullName,
              'role': enrollment.student.role,
              'account_status': enrollment.student.accountStatus,
              'is_active': enrollment.student.isActive ? 1 : 0,
              'enrolled_at': enrollment.enrolledAt.toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache class detail: $e');
    }
  }

  @override
  Future<ClassModel> createClassLocally({
    required String title,
    required String description,
    required String teacherId,
    required String teacherUsername,
    required String teacherFullName,
  }) async {
    try {
      final db = await _localDatabase.database;
      final id = const Uuid().v4();
      final now = DateTime.now();

      final classModel = ClassModel(
        id: id,
        title: title,
        description: description,
        teacherId: teacherId,
        teacherUsername: teacherUsername,
        teacherFullName: teacherFullName,
        isArchived: false,
        studentCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await db.transaction((txn) async {
        // Insert into classes
        final map = classModel.toMap();
        map['cached_at'] = now.toIso8601String();
        map['sync_status'] = 'pending';
        map['is_dirty'] = 1;

        await txn.insert('classes', map);

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.classEntity,
            operation: SyncOperation.create,
            payload: {
              'local_id': id,
              'title': title,
              'description': description,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });

      return classModel;
    } catch (e) {
      throw CacheException('Failed to create class locally: $e');
    }
  }

  @override
  Future<void> updateClassLocally({
    required String classId,
    required String title,
    required String description,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Update class
        await txn.update(
          'classes',
          {
            'title': title,
            'description': description,
            'updated_at': now.toIso8601String(),
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [classId],
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.classEntity,
            operation: SyncOperation.update,
            payload: {
              'id': classId,
              'title': title,
              'description': description,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to update class locally: $e');
    }
  }

  @override
  Future<void> addStudentLocally({
    required String classId,
    required UserModel student,
  }) async {
    try {
      final db = await _localDatabase.database;
      final enrollmentId = const Uuid().v4();
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Insert enrollment
        await txn.insert(
          'class_enrollments',
          {
            'id': enrollmentId,
            'class_id': classId,
            'student_id': student.id,
            'username': student.username,
            'full_name': student.fullName,
            'role': student.role,
            'account_status': student.accountStatus,
            'is_active': student.isActive ? 1 : 0,
            'enrolled_at': now.toIso8601String(),
            'cached_at': now.toIso8601String(),
          },
        );

        // Update class dirty flag
        await txn.update(
          'classes',
          {
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [classId],
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.classEntity,
            operation: SyncOperation.update,
            payload: {
              'id': classId,
              'operation': 'add_student',
              'student_id': student.id,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to add student locally: $e');
    }
  }

  @override
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  }) async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();

      await db.transaction((txn) async {
        // Delete enrollment
        await txn.delete(
          'class_enrollments',
          where: 'class_id = ? AND student_id = ?',
          whereArgs: [classId, studentId],
        );

        // Update class dirty flag
        await txn.update(
          'classes',
          {
            'is_dirty': 1,
            'sync_status': 'pending',
            'cached_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [classId],
        );

        // Enqueue sync
        await _syncQueue.enqueue(
          SyncQueueEntry(
            id: const Uuid().v4(),
            entityType: SyncEntityType.classEntity,
            operation: SyncOperation.update,
            payload: {
              'id': classId,
              'operation': 'remove_student',
              'student_id': studentId,
            },
            status: SyncStatus.pending,
            retryCount: 0,
            maxRetries: 5,
            createdAt: now,
          ),
        );
      });
    } catch (e) {
      throw CacheException('Failed to remove student locally: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await _localDatabase.database;
      // Delete all classes and their enrollments
      await db.delete('enrollments');
      await db.delete('classes');
    } catch (e) {
      throw CacheException('Failed to clear class cache: $e');
    }
  }
}

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.id,
    required super.student,
    required super.enrolledAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as String,
      student: UserModel.fromJson(json['student'] as Map<String, dynamic>),
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
    );
  }
}
