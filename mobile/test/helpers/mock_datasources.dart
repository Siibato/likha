import 'package:mocktail/mocktail.dart';

import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignment_remote_datasource.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessment_remote_datasource.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading_remote_datasource.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth_remote_datasource.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/class_remote_datasource.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_material_remote_datasource.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos_remote_datasource.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/validation/services/validation_service.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/services/storage_service.dart';

// ── Assignment ────────────────────────────────────────────────────────────────

class MockAssignmentLocalDataSource extends Mock
    implements AssignmentLocalDataSource {}

class MockAssignmentRemoteDataSource extends Mock
    implements AssignmentRemoteDataSource {}

// ── Assessment ────────────────────────────────────────────────────────────────

class MockAssessmentLocalDataSource extends Mock
    implements AssessmentLocalDataSource {}

class MockAssessmentRemoteDataSource extends Mock
    implements AssessmentRemoteDataSource {}

// ── Grading ───────────────────────────────────────────────────────────────────

class MockGradingLocalDataSource extends Mock
    implements GradingLocalDataSource {}

class MockGradingRemoteDataSource extends Mock
    implements GradingRemoteDataSource {}

// ── Infrastructure ────────────────────────────────────────────────────────────

class MockServerReachabilityService extends Mock
    implements ServerReachabilityService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockValidationService extends Mock implements ValidationService {}

class MockStorageService extends Mock implements StorageService {}

class MockDataEventBus extends Mock implements DataEventBus {}

class MockSyncLogger extends Mock implements SyncLogger {}

// ── Auth ──────────────────────────────────────────────────────────────────────

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

// ── Class ─────────────────────────────────────────────────────────────────────

class MockClassLocalDataSource extends Mock implements ClassLocalDataSource {}

class MockClassRemoteDataSource extends Mock implements ClassRemoteDataSource {}

// ── Learning Material ─────────────────────────────────────────────────────────

class MockLearningMaterialLocalDataSource extends Mock
    implements LearningMaterialLocalDataSource {}

class MockLearningMaterialRemoteDataSource extends Mock
    implements LearningMaterialRemoteDataSource {}

// ── TOS ───────────────────────────────────────────────────────────────────────

class MockTosLocalDataSource extends Mock implements TosLocalDataSource {}

class MockTosRemoteDataSource extends Mock implements TosRemoteDataSource {}

// ── Database ──────────────────────────────────────────────────────────────────

class MockLocalDatabase extends Mock implements LocalDatabase {}
