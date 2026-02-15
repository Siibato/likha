import 'package:flutter/foundation.dart';
import 'package:likha/core/validation/services/data_validator.dart';
import 'package:likha/domain/classes/data/datasources/class_local_datasource.dart';
import 'package:likha/domain/classes/data/datasources/class_remote_datasource.dart';
import 'package:likha/domain/assessments/data/datasources/assessment_local_datasource.dart';
import 'package:likha/domain/assessments/data/datasources/assessment_remote_datasource.dart';
import 'package:likha/domain/assignments/data/datasources/assignment_local_datasource.dart';
import 'package:likha/domain/assignments/data/datasources/assignment_remote_datasource.dart';
import 'package:likha/domain/learning_materials/data/datasources/learning_material_local_datasource.dart';
import 'package:likha/domain/learning_materials/data/datasources/learning_material_remote_datasource.dart';

class ValidationService {
  final DataValidator _validator;
  final ClassLocalDataSource _classLocal;
  final AssessmentLocalDataSource _assessmentLocal;
  final AssignmentLocalDataSource _assignmentLocal;
  final LearningMaterialLocalDataSource _materialLocal;
  final ClassRemoteDataSource _classRemote;
  final AssessmentRemoteDataSource _assessmentRemote;
  final AssignmentRemoteDataSource _assignmentRemote;
  final LearningMaterialRemoteDataSource _materialRemote;

  ValidationService({
    required DataValidator validator,
    required ClassLocalDataSource classLocal,
    required AssessmentLocalDataSource assessmentLocal,
    required AssignmentLocalDataSource assignmentLocal,
    required LearningMaterialLocalDataSource materialLocal,
    required ClassRemoteDataSource classRemote,
    required AssessmentRemoteDataSource assessmentRemote,
    required AssignmentRemoteDataSource assignmentRemote,
    required LearningMaterialRemoteDataSource materialRemote,
  })  : _validator = validator,
        _classLocal = classLocal,
        _assessmentLocal = assessmentLocal,
        _assignmentLocal = assignmentLocal,
        _materialLocal = materialLocal,
        _classRemote = classRemote,
        _assessmentRemote = assessmentRemote,
        _assignmentRemote = assignmentRemote,
        _materialRemote = materialRemote;

  /// Validate and sync a single entity type
  Future<void> validateAndSync(String entityType) async {
    try {
      final result = await _validator.validate(entityType);

      // If data is outdated, fetch and update
      if (result.isOutdated) {
        await _syncEntity(entityType);
      }
    } catch (e) {
      debugPrint('Validation error for $entityType: $e');
    }
  }

  /// Fetch fresh data and update SQLite
  Future<void> _syncEntity(String entityType) async {
    switch (entityType) {
      case 'classes':
        // Note: This needs to be called with proper context from repositories
        // For now, we cannot get all classes without knowing if teacher or student
        debugPrint('Classes sync: needs context from repository');
        break;
      case 'assessments':
        // Similar issue - needs class context
        debugPrint('Assessments sync: needs class context from repository');
        break;
      case 'assignments':
        // Similar issue - needs class context
        debugPrint('Assignments sync: needs class context from repository');
        break;
      case 'learning_materials':
        // Similar issue - needs class context
        debugPrint('Learning materials sync: needs class context from repository');
        break;
    }
  }

  /// Sync classes (called from ClassRepository with proper context)
  Future<void> syncClasses() async {
    try {
      // Note: In real implementation, this would be called from the repository
      // which has the context (teacher_id or student_id)
      debugPrint('Syncing classes...');
    } catch (e) {
      debugPrint('Error syncing classes: $e');
    }
  }

  /// Sync assessments for a class (called from AssessmentRepository)
  Future<void> syncAssessments(String classId) async {
    try {
      final fresh = await _assessmentRemote.getAssessments(classId: classId);
      await _assessmentLocal.cacheAssessments(fresh);
      debugPrint('Synced assessments for class $classId');
    } catch (e) {
      debugPrint('Error syncing assessments: $e');
    }
  }

  /// Sync assignments for a class (called from AssignmentRepository)
  Future<void> syncAssignments(String classId) async {
    try {
      final fresh = await _assignmentRemote.getAssignments(classId: classId);
      await _assignmentLocal.cacheAssignments(fresh);
      debugPrint('Synced assignments for class $classId');
    } catch (e) {
      debugPrint('Error syncing assignments: $e');
    }
  }

  /// Sync learning materials for a class (called from LearningMaterialRepository)
  Future<void> syncLearningMaterials(String classId) async {
    try {
      final fresh = await _materialRemote.getMaterials(classId: classId);
      await _materialLocal.cacheMaterials(fresh);
      debugPrint('Synced learning materials for class $classId');
    } catch (e) {
      debugPrint('Error syncing learning materials: $e');
    }
  }
}
