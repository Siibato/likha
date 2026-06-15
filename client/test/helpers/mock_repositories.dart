import 'package:mocktail/mocktail.dart';

// Auth
import 'package:likha/domain/auth/repositories/auth_repository.dart';

// Assignments
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

// Assessments
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

// Grading
import 'package:likha/domain/grading/repositories/grading_repository.dart';

// Classes
import 'package:likha/domain/classes/repositories/class_repository.dart';

// TOS
import 'package:likha/domain/tos/repositories/tos_repository.dart';

// Learning Materials
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';

// Core
import 'package:likha/core/sync/sync_queue.dart';

// Auth Repository Mock
class MockAuthRepository extends Mock implements AuthRepository {}

// Assignment Repository Mock
class MockAssignmentRepository extends Mock implements AssignmentRepository {}

// Assessment Repository Mock
class MockAssessmentRepository extends Mock implements AssessmentRepository {}

// Grading Repository Mock
class MockGradingRepository extends Mock implements GradingRepository {}

// Class Repository Mock
class MockClassRepository extends Mock implements ClassRepository {}

// TOS Repository Mock
class MockTosRepository extends Mock implements TosRepository {}

// Learning Material Repository Mock
class MockLearningMaterialRepository extends Mock implements LearningMaterialRepository {}

// Core Service Mocks
class MockSyncQueue extends Mock implements SyncQueue {}
