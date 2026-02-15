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

      // If data is outdated, clear cache so repository will refetch fresh data
      if (result.isOutdated) {
        debugPrint('Data outdated for $entityType - clearing cache to force refetch');
        await _clearCacheForEntity(entityType);
      }
    } catch (e) {
      debugPrint('Validation error for $entityType: $e');
    }
  }

  /// Clear cached data for a specific entity type
  Future<void> _clearCacheForEntity(String entityType) async {
    try {
      switch (entityType) {
        case 'classes':
          await _classLocal.clearAllCache();
          break;
        case 'assessments':
          await _assessmentLocal.clearAllCache();
          break;
        case 'assignments':
          await _assignmentLocal.clearAllCache();
          break;
        case 'learning_materials':
          await _materialLocal.clearAllCache();
          break;
      }
      debugPrint('Cleared cache for $entityType');
    } catch (e) {
      debugPrint('Error clearing cache for $entityType: $e');
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
