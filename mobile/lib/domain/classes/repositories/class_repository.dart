import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';

abstract class ClassRepository {
  ResultFuture<ClassEntity> createClass({
    required String title,
    String? description,
    String? teacherId,
    String? teacherUsername,
    String? teacherFullName,
  });

  ResultFuture<List<ClassEntity>> getMyClasses({bool skipBackgroundRefresh = false});

  ResultFuture<List<ClassEntity>> getAllClasses({bool skipBackgroundRefresh = false});

  ResultFuture<ClassDetail> getClassDetail({required String classId});

  ResultFuture<ClassEntity> updateClass({
    required String classId,
    String? title,
    String? description,
    String? teacherId,
  });

  ResultFuture<Participant> addStudent({
    required String classId,
    required String studentId,
  });

  ResultVoid removeStudent({
    required String classId,
    required String studentId,
  });

  ResultFuture<List<User>> searchStudents({String? query});

  ResultFuture<List<User>> getParticipants({required String classId});
}
