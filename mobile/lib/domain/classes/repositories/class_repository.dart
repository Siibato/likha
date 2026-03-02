import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';

abstract class ClassRepository {
  ResultFuture<ClassEntity> createClass({
    required String title,
    String? description,
    String? teacherId,
  });

  ResultFuture<List<ClassEntity>> getMyClasses();

  ResultFuture<List<ClassEntity>> getAllClasses();

  ResultFuture<ClassDetail> getClassDetail({required String classId});

  ResultFuture<ClassEntity> updateClass({
    required String classId,
    String? title,
    String? description,
  });

  ResultFuture<Enrollment> addStudent({
    required String classId,
    required String studentId,
  });

  ResultVoid removeStudent({
    required String classId,
    required String studentId,
  });

  ResultFuture<List<User>> searchStudents({String? query});
}
