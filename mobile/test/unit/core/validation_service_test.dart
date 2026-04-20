import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import 'package:likha/core/validation/services/data_validator.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/core/validation/models/validation_result.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_material_remote_datasource.dart';

class MockDataValidator extends Mock implements DataValidator {}
class MockClassLocalDataSource extends Mock implements ClassLocalDataSource {}
class MockAssessmentLocalDataSource extends Mock implements AssessmentLocalDataSource {}
class MockAssessmentRemoteDataSource extends Mock implements AssessmentRemoteDataSource {}
class MockAssignmentLocalDataSource extends Mock implements AssignmentLocalDataSource {}
class MockAssignmentRemoteDataSource extends Mock implements AssignmentRemoteDataSource {}
class MockLearningMaterialLocalDataSource extends Mock implements LearningMaterialLocalDataSource {}
class MockLearningMaterialRemoteDataSource extends Mock implements LearningMaterialRemoteDataSource {}

ValidationResult makeResult({required String entityType, required bool isOutdated}) {
  return ValidationResult(
    entityType: entityType,
    isOutdated: isOutdated,
    serverTimestamp: DateTime(2024, 1, 1),
    serverRecordCount: 5,
    isOnline: true,
  );
}

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'VALIDATION_LOGGING_ENABLED=false');
  });

  late ValidationService service;
  late MockDataValidator mockValidator;
  late MockClassLocalDataSource mockClassLocal;
  late MockAssessmentLocalDataSource mockAssessmentLocal;
  late MockAssessmentRemoteDataSource mockAssessmentRemote;
  late MockAssignmentLocalDataSource mockAssignmentLocal;
  late MockAssignmentRemoteDataSource mockAssignmentRemote;
  late MockLearningMaterialLocalDataSource mockMaterialLocal;
  late MockLearningMaterialRemoteDataSource mockMaterialRemote;

  setUp(() {
    mockValidator = MockDataValidator();
    mockClassLocal = MockClassLocalDataSource();
    mockAssessmentLocal = MockAssessmentLocalDataSource();
    mockAssessmentRemote = MockAssessmentRemoteDataSource();
    mockAssignmentLocal = MockAssignmentLocalDataSource();
    mockAssignmentRemote = MockAssignmentRemoteDataSource();
    mockMaterialLocal = MockLearningMaterialLocalDataSource();
    mockMaterialRemote = MockLearningMaterialRemoteDataSource();

    service = ValidationService(
      validator: mockValidator,
      classLocal: mockClassLocal,
      assessmentLocal: mockAssessmentLocal,
      assignmentLocal: mockAssignmentLocal,
      materialLocal: mockMaterialLocal,
      assessmentRemote: mockAssessmentRemote,
      assignmentRemote: mockAssignmentRemote,
      materialRemote: mockMaterialRemote,
    );
  });

  group('ValidationService.validateAndSync', () {
    test('clears class cache when classes data is outdated', () async {
      when(() => mockValidator.validate('classes'))
          .thenAnswer((_) async => makeResult(entityType: 'classes', isOutdated: true));
      when(() => mockClassLocal.clearAllCache()).thenAnswer((_) async {});

      await service.validateAndSync('classes');

      verify(() => mockClassLocal.clearAllCache()).called(1);
    });

    test('does not clear cache when classes data is fresh', () async {
      when(() => mockValidator.validate('classes'))
          .thenAnswer((_) async => makeResult(entityType: 'classes', isOutdated: false));

      await service.validateAndSync('classes');

      verifyNever(() => mockClassLocal.clearAllCache());
    });

    test('clears assessment cache when assessments data is outdated', () async {
      when(() => mockValidator.validate('assessments'))
          .thenAnswer((_) async => makeResult(entityType: 'assessments', isOutdated: true));
      when(() => mockAssessmentLocal.clearAllCache()).thenAnswer((_) async {});

      await service.validateAndSync('assessments');

      verify(() => mockAssessmentLocal.clearAllCache()).called(1);
    });

    test('does not clear assessment cache when data is fresh', () async {
      when(() => mockValidator.validate('assessments'))
          .thenAnswer((_) async => makeResult(entityType: 'assessments', isOutdated: false));

      await service.validateAndSync('assessments');

      verifyNever(() => mockAssessmentLocal.clearAllCache());
    });

    test('clears assignment cache when assignments data is outdated', () async {
      when(() => mockValidator.validate('assignments'))
          .thenAnswer((_) async => makeResult(entityType: 'assignments', isOutdated: true));
      when(() => mockAssignmentLocal.clearAllCache()).thenAnswer((_) async {});

      await service.validateAndSync('assignments');

      verify(() => mockAssignmentLocal.clearAllCache()).called(1);
    });

    test('clears material cache when learning_materials data is outdated', () async {
      when(() => mockValidator.validate('learning_materials'))
          .thenAnswer((_) async => makeResult(entityType: 'learning_materials', isOutdated: true));
      when(() => mockMaterialLocal.clearAllCache()).thenAnswer((_) async {});

      await service.validateAndSync('learning_materials');

      verify(() => mockMaterialLocal.clearAllCache()).called(1);
    });

    test('does not throw when validator throws', () async {
      when(() => mockValidator.validate(any()))
          .thenThrow(Exception('Validator error'));

      expect(
        () => service.validateAndSync('classes'),
        returnsNormally,
      );
    });

    test('does not throw when cache clear throws', () async {
      when(() => mockValidator.validate('classes'))
          .thenAnswer((_) async => makeResult(entityType: 'classes', isOutdated: true));
      when(() => mockClassLocal.clearAllCache())
          .thenThrow(Exception('Cache error'));

      expect(
        () => service.validateAndSync('classes'),
        returnsNormally,
      );
    });
  });

  group('ValidationService.syncAssessments', () {
    test('fetches from remote and caches when called', () async {
      when(() => mockAssessmentRemote.getAssessments(classId: any(named: 'classId')))
          .thenAnswer((_) async => []);
      when(() => mockAssessmentLocal.cacheAssessments(any()))
          .thenAnswer((_) async {});

      await service.syncAssessments('class-1');

      verify(() => mockAssessmentRemote.getAssessments(classId: 'class-1')).called(1);
      verify(() => mockAssessmentLocal.cacheAssessments(any())).called(1);
    });

    test('does not throw when remote call throws', () async {
      when(() => mockAssessmentRemote.getAssessments(classId: any(named: 'classId')))
          .thenThrow(Exception('Remote error'));

      expect(
        () => service.syncAssessments('class-1'),
        returnsNormally,
      );
    });
  });

  group('ValidationService.syncAssignments', () {
    test('fetches from remote and caches when called', () async {
      when(() => mockAssignmentRemote.getAssignments(classId: any(named: 'classId')))
          .thenAnswer((_) async => []);
      when(() => mockAssignmentLocal.cacheAssignments(any()))
          .thenAnswer((_) async {});

      await service.syncAssignments('class-1');

      verify(() => mockAssignmentRemote.getAssignments(classId: 'class-1')).called(1);
      verify(() => mockAssignmentLocal.cacheAssignments(any())).called(1);
    });

    test('does not throw when remote call throws', () async {
      when(() => mockAssignmentRemote.getAssignments(classId: any(named: 'classId')))
          .thenThrow(Exception('Remote error'));

      expect(
        () => service.syncAssignments('class-1'),
        returnsNormally,
      );
    });
  });

  group('ValidationService.syncLearningMaterials', () {
    test('fetches from remote and caches when called', () async {
      when(() => mockMaterialRemote.getMaterials(classId: any(named: 'classId')))
          .thenAnswer((_) async => []);
      when(() => mockMaterialLocal.cacheMaterials(any()))
          .thenAnswer((_) async {});

      await service.syncLearningMaterials('class-1');

      verify(() => mockMaterialRemote.getMaterials(classId: 'class-1')).called(1);
      verify(() => mockMaterialLocal.cacheMaterials(any())).called(1);
    });

    test('does not throw when remote call throws', () async {
      when(() => mockMaterialRemote.getMaterials(classId: any(named: 'classId')))
          .thenThrow(Exception('Remote error'));

      expect(
        () => service.syncLearningMaterials('class-1'),
        returnsNormally,
      );
    });
  });

  group('ValidationService.syncClasses', () {
    test('completes without error', () async {
      expect(
        () => service.syncClasses(),
        returnsNormally,
      );
    });
  });
}
