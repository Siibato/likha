import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/core/config/api_config.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/services/school_setup_service_impl.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/network/server_reachability_service.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/logging/sync_logger.dart';
import 'package:likha/data/validation/services/validation_service.dart';
import 'package:likha/data/validation/services/data_validator.dart';
import 'package:likha/data/validation/services/timestamp_validator.dart';
import 'package:likha/data/validation/data_sources/validation_remote_datasource.dart';
import 'package:likha/data/validation/repositories/validation_metadata_repository.dart';
import 'package:likha/data/datasources/local/assessments/assessment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assessments/assessment_remote_datasource.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_impl.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_statistics.dart';
import 'package:likha/domain/assessments/usecases/get_student_results.dart';
import 'package:likha/domain/assessments/usecases/get_student_submission.dart';
import 'package:likha/domain/assessments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assessments/usecases/get_submissions.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/usecases/unpublish_assessment.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/usecases/save_answers.dart';
import 'package:likha/domain/assessments/usecases/start_assessment.dart';
import 'package:likha/domain/assessments/usecases/submit_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/domain/assessments/usecases/delete_question.dart';
import 'package:likha/domain/assessments/usecases/reorder_assessment.dart';
import 'package:likha/domain/assessments/usecases/reorder_questions.dart';
import 'package:likha/data/datasources/local/assignments/assignment_local_datasource.dart';
import 'package:likha/data/datasources/remote/assignments/assignment_remote_datasource.dart';
import 'package:likha/data/repositories/assignments/assignment_repository_impl.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/delete_assignment.dart';
import 'package:likha/domain/assignments/usecases/delete_file.dart';
import 'package:likha/domain/assignments/usecases/download_file.dart';
import 'package:likha/domain/assignments/usecases/get_assignment_detail.dart';
import 'package:likha/domain/assignments/usecases/get_assignments.dart';
import 'package:likha/domain/assignments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assignments/usecases/get_submissions.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/domain/assignments/usecases/publish_assignment.dart';
import 'package:likha/domain/assignments/usecases/unpublish_assignment.dart';
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/domain/assignments/usecases/reorder_assignment.dart';
import 'package:likha/domain/assignments/usecases/get_student_assignment_submission.dart';
import 'package:likha/data/datasources/local/auth/auth_local_datasource.dart';
import 'package:likha/data/datasources/remote/auth/auth_remote_datasource.dart';
import 'package:likha/data/repositories/auth/auth_repository_impl.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/create_account.dart';
import 'package:likha/domain/auth/usecases/get_activity_logs.dart';
import 'package:likha/domain/auth/usecases/get_all_accounts.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/usecases/lock_account.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/usecases/logout.dart';
import 'package:likha/domain/auth/usecases/reset_account.dart';
import 'package:likha/domain/auth/usecases/update_account.dart';
import 'package:likha/data/datasources/local/classes/class_local_datasource.dart';
import 'package:likha/data/datasources/remote/classes/class_remote_datasource.dart';
import 'package:likha/data/repositories/classes/class_repository_impl.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/auth/usecases/delete_account.dart';
import 'package:likha/domain/classes/usecases/delete_class.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/get_all_classes.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_participants.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/data/datasources/local/learning_materials/learning_material_local_datasource.dart';
import 'package:likha/data/datasources/remote/learning_materials/learning_material_remote_datasource.dart';
import 'package:likha/data/datasources/remote/sync/sync_remote_datasource.dart';
import 'package:likha/data/repositories/learning_materials/learning_material_repository_impl.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';
import 'package:likha/domain/learning_materials/usecases/create_material.dart';
import 'package:likha/domain/learning_materials/usecases/delete_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/delete_material.dart';
import 'package:likha/domain/learning_materials/usecases/download_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/get_material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/get_materials.dart';
import 'package:likha/domain/learning_materials/usecases/reorder_material.dart' as reorder;
import 'package:likha/domain/learning_materials/usecases/update_material.dart';
import 'package:likha/domain/learning_materials/usecases/upload_file.dart' as material;
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/repositories/grading/grading_repository_impl.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';
import 'package:likha/domain/grading/usecases/clear_score_override.dart';
import 'package:likha/domain/grading/usecases/compute_grades.dart';
import 'package:likha/domain/grading/usecases/create_grade_item.dart';
import 'package:likha/domain/grading/usecases/delete_grade_item.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/domain/grading/usecases/get_grade_items.dart';
import 'package:likha/domain/grading/usecases/get_grade_summary.dart';
import 'package:likha/domain/grading/usecases/get_grading_config.dart';
import 'package:likha/domain/grading/usecases/get_my_grade_detail.dart';
import 'package:likha/domain/grading/usecases/get_my_grades.dart';
import 'package:likha/domain/grading/usecases/get_term_grades.dart';
import 'package:likha/domain/grading/usecases/get_scores_by_item.dart';
import 'package:likha/domain/grading/usecases/save_scores.dart';
import 'package:likha/domain/grading/usecases/set_score_override.dart';
import 'package:likha/domain/grading/usecases/setup_grading.dart';
import 'package:likha/domain/grading/usecases/update_grade_item.dart';
import 'package:likha/domain/grading/usecases/update_grading_config.dart';
import 'package:likha/domain/grading/usecases/get_general_averages.dart';
import 'package:likha/domain/grading/usecases/get_sf9.dart';
import 'package:likha/domain/grading/usecases/get_sf10.dart';
import 'package:likha/domain/grading/usecases/update_term_grade.dart';
import 'package:likha/domain/grading/services/score_generation_service.dart';
import 'package:likha/domain/grading/usecases/generate_scores.dart';
import 'package:likha/domain/grading/usecases/get_class_grades.dart';
import 'package:likha/domain/grading/usecases/get_grade_data_batch.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/data/datasources/remote/tos/tos_remote_datasource.dart';
import 'package:likha/data/repositories/tos/tos_repository_impl.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';
import 'package:likha/domain/tos/usecases/get_tos_list.dart';
import 'package:likha/domain/tos/usecases/get_tos_detail.dart';
import 'package:likha/domain/tos/usecases/create_tos.dart';
import 'package:likha/domain/tos/usecases/update_tos.dart';
import 'package:likha/domain/tos/usecases/delete_tos.dart';
import 'package:likha/domain/tos/usecases/add_competency.dart';
import 'package:likha/domain/tos/usecases/update_competency.dart';
import 'package:likha/domain/tos/usecases/delete_competency.dart';
import 'package:likha/domain/tos/usecases/bulk_add_competencies.dart';
import 'package:likha/domain/tos/usecases/search_melcs.dart';
import 'package:likha/data/datasources/local/setup/setup_local_datasource.dart';
import 'package:likha/data/datasources/remote/setup/setup_remote_datasource.dart';
import 'package:likha/data/repositories/setup/setup_repository_impl.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';
import 'package:likha/domain/setup/usecases/get_school_details.dart';
import 'package:likha/domain/setup/usecases/update_school_details.dart';
import 'package:likha/domain/setup/usecases/update_school_code.dart';
import 'package:likha/domain/document_exports/repositories/document_export_repository.dart';
import 'package:likha/domain/document_exports/usecases/export_class_grades.dart';
import 'package:likha/domain/document_exports/usecases/export_sf9.dart';
import 'package:likha/domain/document_exports/usecases/export_sf10.dart';
import 'package:likha/data/datasources/remote/document_exports/document_export_remote_datasource.dart';
import 'package:likha/data/repositories/document_exports/document_export_repository_impl.dart';
import 'package:likha/data/datasources/remote/student_records/student_records_remote_datasource.dart';
import 'package:likha/data/datasources/local/student_records/student_records_local_datasource.dart';
import 'package:likha/data/repositories/student_records/student_records_repository_impl.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';
import 'package:likha/domain/student_records/usecases/get_learner_details.dart';
import 'package:likha/domain/student_records/usecases/upsert_learner_details.dart';
import 'package:likha/domain/student_records/usecases/get_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_attendance.dart';
import 'package:likha/domain/student_records/usecases/get_core_values.dart';
import 'package:likha/domain/student_records/usecases/upsert_core_values.dart';
import 'package:likha/domain/student_records/usecases/get_sf10_v2.dart';
import 'package:likha/domain/student_records/usecases/get_school_history.dart';
import 'package:likha/domain/student_records/usecases/create_school_history.dart';
import 'package:likha/domain/student_records/usecases/update_school_history.dart';
import 'package:likha/domain/student_records/usecases/delete_school_history.dart';
import 'package:likha/domain/student_records/usecases/get_previous_subjects.dart';
import 'package:likha/domain/student_records/usecases/upsert_previous_subject.dart';
import 'package:likha/domain/student_records/usecases/get_previous_attendance.dart';
import 'package:likha/domain/student_records/usecases/upsert_previous_attendance.dart';
import 'package:likha/services/storage_service.dart';
final sl = GetIt.instance;

Future<void> init() async {
  if (sl.isRegistered<FlutterSecureStorage>()) {
    return;
  }

  // External
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  sl.registerLazySingleton(() => secureStorage);

  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);

  // School setup service — registered early so ApiConstants.baseUrl can be set
  // before any network service is initialized.
  sl.registerLazySingleton<SchoolSetupService>(
    () => SchoolSetupServiceImpl(sl<SharedPreferences>(), Dio()),
  );

  // Bootstrap runtime base URL from stored school config (if available).
  final schoolConfig = await sl<SchoolSetupService>().getSchoolConfig();
  if (schoolConfig != null) {
    ApiConstants.setRuntimeBaseUrl(schoolConfig.serverUrl);
  }

  // Core - Database (first, depends on nothing)
  final localDb = LocalDatabase();
  await localDb.initialize();
  sl.registerSingleton<LocalDatabase>(localDb);

  // Core - Connectivity (needed by repositories)
  sl.registerSingleton<ConnectivityService>(
    ConnectivityServiceImpl(Connectivity()),
  );
  await sl<ConnectivityService>().initialize();

  // Core - Sync infrastructure
  sl.registerLazySingleton<SyncQueue>(() => SyncQueueImpl(sl<LocalDatabase>()));

  // Core - Event Bus (must be before repositories)
  sl.registerSingleton<DataEventBus>(DataEventBus());

  // Core - General
  sl.registerLazySingleton(() => kIsWeb
      ? StorageService(sl<FlutterSecureStorage>(), sl<SharedPreferences>())
      : StorageService(sl<FlutterSecureStorage>()));

  // Core - Server Reachability (must be before DioClient to avoid circular dependency)
  // Standalone Dio for health checks — does NOT go through DioClient.
  // Used only by ServerReachabilityService; not registered in the service locator.
  final healthDio = Dio()
    ..options.baseUrl = ApiConstants.baseUrl
    ..options.connectTimeout = ApiConstants.connectTimeout
    ..options.receiveTimeout = ApiConstants.receiveTimeout
    ..options.responseType = ResponseType.json;

  sl.registerSingleton<ServerReachabilityService>(
    ServerReachabilityServiceImpl(healthDio),
  );
  await sl<ServerReachabilityService>().initialize();

  // DioClient now receives ServerReachabilityService (no circular ref).
  sl.registerLazySingleton(
    () => DioClient(sl<StorageService>(), sl<ServerReachabilityService>()),
  );

  // Remote Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<DioClient>(), sl<StorageService>()),
  );
  sl.registerLazySingleton<ClassRemoteDataSource>(
    () => ClassRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<AssessmentRemoteDataSource>(
    () => AssessmentRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<AssignmentRemoteDataSource>(
    () => AssignmentRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<LearningMaterialRemoteDataSource>(
    () => LearningMaterialRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<GradingRemoteDataSource>(
    () => GradingRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<SetupRemoteDataSource>(
    () => SetupRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<TosRemoteDataSource>(
    () => TosRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<DocumentExportRemoteDataSource>(
    () => DocumentExportRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<StudentRecordsRemoteDataSource>(
    () => StudentRecordsRemoteDataSourceImpl(sl<DioClient>()),
  );

  // Local Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<ClassLocalDataSource>(
    () => ClassLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<AssessmentLocalDataSource>(
    () => AssessmentLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<AssignmentLocalDataSource>(
    () => AssignmentLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<LearningMaterialLocalDataSource>(
    () => LearningMaterialLocalDataSourceImpl(
      sl<LocalDatabase>(),
      sl<SyncQueue>(),
    ),
  );
  sl.registerLazySingleton<SetupLocalDataSource>(
    () => SetupLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<GradingLocalDataSource>(
    () => GradingLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<TosLocalDataSource>(
    () => TosLocalDataSourceImpl(sl<LocalDatabase>(), sl<SyncQueue>()),
  );
  sl.registerLazySingleton<StudentRecordsLocalDataSource>(
    () => StudentRecordsLocalDataSourceImpl(sl<LocalDatabase>()),
  );

  // Validation services
  sl.registerLazySingleton<ValidationRemoteDataSource>(
    () => ValidationRemoteDataSourceImpl(sl<DioClient>()),
  );

  sl.registerLazySingleton<ValidationMetadataRepository>(
    () => ValidationMetadataRepositoryImpl(sl<LocalDatabase>()),
  );

  sl.registerLazySingleton<DataValidator>(
    () => TimestampValidator(
      remoteDataSource: sl<ValidationRemoteDataSource>(),
      metadataRepository: sl<ValidationMetadataRepository>(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );

  sl.registerLazySingleton<ValidationService>(
    () => ValidationService(
      validator: sl<DataValidator>(),
      classLocal: sl<ClassLocalDataSource>(),
      assessmentLocal: sl<AssessmentLocalDataSource>(),
      assignmentLocal: sl<AssignmentLocalDataSource>(),
      materialLocal: sl<LearningMaterialLocalDataSource>(),
      assessmentRemote: sl<AssessmentRemoteDataSource>(),
      assignmentRemote: sl<AssignmentRemoteDataSource>(),
      materialRemote: sl<LearningMaterialRemoteDataSource>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      storageService: sl<StorageService>(),
      syncQueue: sl<SyncQueue>(),
      classLocalDataSource: sl<ClassLocalDataSource>(),
      assignmentLocalDataSource: sl<AssignmentLocalDataSource>(),
      assessmentLocalDataSource: sl<AssessmentLocalDataSource>(),
      learningMaterialLocalDataSource: sl<LearningMaterialLocalDataSource>(),
      gradingLocalDataSource: sl<GradingLocalDataSource>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );
  sl.registerLazySingleton<ClassRepository>(
    () => ClassRepositoryImpl(
      remoteDataSource: sl<ClassRemoteDataSource>(),
      localDataSource: sl<ClassLocalDataSource>(),
      syncQueue: sl<SyncQueue>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );
  sl.registerLazySingleton<AssessmentRepository>(
    () => AssessmentRepositoryImpl(
      remoteDataSource: sl<AssessmentRemoteDataSource>(),
      localDataSource: sl<AssessmentLocalDataSource>(),
      validationService: sl<ValidationService>(),
      connectivityService: sl<ConnectivityService>(),
      syncQueue: sl<SyncQueue>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );
  sl.registerLazySingleton<AssignmentRepository>(
    () => AssignmentRepositoryImpl(
      remoteDataSource: sl<AssignmentRemoteDataSource>(),
      localDataSource: sl<AssignmentLocalDataSource>(),
      syncQueue: sl<SyncQueue>(),
      storageService: sl<StorageService>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );
  sl.registerLazySingleton<LearningMaterialRepository>(
    () => LearningMaterialRepositoryImpl(
      remoteDataSource: sl<LearningMaterialRemoteDataSource>(),
      localDataSource: sl<LearningMaterialLocalDataSource>(),
      syncQueue: sl<SyncQueue>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );

  // Sync Logger
  sl.registerSingleton<SyncLogger>(SyncLogger());

  // Server Clock Service (must be registered before SyncManager)
  sl.registerSingleton<ServerClockService>(ServerClockService());

  // SyncManager (depends on all repositories)
  sl.registerSingleton<SyncManager>(
    SyncManager(
      sl<ServerReachabilityService>(), // ServerReachabilityService
      sl<SyncQueue>(), // SyncQueue
      sl<SyncRemoteDataSource>(), // SyncRemoteDataSource
      sl<LocalDatabase>(), // LocalDatabase
      sl<AssessmentRemoteDataSource>(), // AssessmentRemoteDataSource
      sl<AssessmentLocalDataSource>(), // AssessmentLocalDataSource
      sl<AssignmentRemoteDataSource>(), // AssignmentRemoteDataSource
      sl<AssignmentLocalDataSource>(), // AssignmentLocalDataSource
      sl<AuthRemoteDataSource>(), // AuthRemoteDataSource
      sl<AuthLocalDataSource>(), // AuthLocalDataSource
      sl<ClassRemoteDataSource>(), // ClassRemoteDataSource
      sl<ClassLocalDataSource>(), // ClassLocalDataSource
      sl<GradingRemoteDataSource>(), // GradingRemoteDataSource
      sl<GradingLocalDataSource>(), // GradingLocalDataSource
      sl<LearningMaterialRemoteDataSource>(), // LearningMaterialRemoteDataSource
      sl<LearningMaterialLocalDataSource>(), // LearningMaterialLocalDataSource
      sl<SetupRemoteDataSource>(), // SetupRemoteDataSource
      sl<StudentRecordsRemoteDataSource>(), // StudentRecordsRemoteDataSource
      sl<TosRemoteDataSource>(), // TosRemoteDataSource
      sl<TosLocalDataSource>(), // TosLocalDataSource
      sl<SyncLogger>(), // SyncLogger
      sl<StorageService>(), // StorageService
      sl<ServerClockService>(), // ServerClockService
      sl<DataEventBus>(), // DataEventBus
    ),
  );

  // Auth use cases
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => CheckUsername(sl()));
  sl.registerLazySingleton(() => ActivateAccount(sl()));
  sl.registerLazySingleton(() => CreateAccount(sl()));
  sl.registerLazySingleton(() => GetAllAccounts(sl()));
  sl.registerLazySingleton(() => ResetAccount(sl()));
  sl.registerLazySingleton(() => LockAccount(sl()));
  sl.registerLazySingleton(() => GetActivityLogs(sl()));
  sl.registerLazySingleton(() => UpdateAccount(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  // Class use cases
  sl.registerLazySingleton(() => CreateClass(sl()));
  sl.registerLazySingleton(() => GetMyClasses(sl()));
  sl.registerLazySingleton(() => GetAllClasses(sl()));
  sl.registerLazySingleton(() => GetClassDetail(sl()));
  sl.registerLazySingleton(() => UpdateClass(sl()));
  sl.registerLazySingleton(() => AddStudent(sl()));
  sl.registerLazySingleton(() => RemoveStudent(sl()));
  sl.registerLazySingleton(() => SearchStudents(sl()));
  sl.registerLazySingleton(() => GetParticipants(sl()));
  sl.registerLazySingleton(() => DeleteClass(sl()));

  // Assessment use cases
  sl.registerLazySingleton(() => CreateAssessment(sl()));
  sl.registerLazySingleton(() => GetAssessments(sl()));
  sl.registerLazySingleton(() => GetAssessmentDetail(sl()));
  sl.registerLazySingleton(() => PublishAssessment(sl()));
  sl.registerLazySingleton(() => UnpublishAssessment(sl()));
  sl.registerLazySingleton(() => DeleteAssessment(sl()));
  sl.registerLazySingleton(() => AddQuestions(sl()));
  sl.registerLazySingleton(() => GetSubmissions(sl()));
  sl.registerLazySingleton(() => GetSubmissionDetail(sl()));
  sl.registerLazySingleton(() => OverrideAnswer(sl()));
  sl.registerLazySingleton(() => GradeEssay(sl()));
  sl.registerLazySingleton(() => ReleaseResults(sl()));
  sl.registerLazySingleton(() => GetStatistics(sl()));
  sl.registerLazySingleton(() => StartAssessment(sl()));
  sl.registerLazySingleton(() => SaveAnswers(sl()));
  sl.registerLazySingleton(() => SubmitAssessment(sl()));
  sl.registerLazySingleton(() => GetStudentResults(sl()));
  sl.registerLazySingleton(() => GetStudentSubmission(sl()));
  sl.registerLazySingleton(() => UpdateAssessment(sl()));
  sl.registerLazySingleton(() => UpdateQuestion(sl()));
  sl.registerLazySingleton(() => DeleteQuestion(sl()));
  sl.registerLazySingleton(() => ReorderAllQuestions(sl()));
  sl.registerLazySingleton(() => ReorderAllAssessments(sl()));

  // Assignment use cases
  sl.registerLazySingleton(() => CreateAssignment(sl()));
  sl.registerLazySingleton(() => GetAssignments(sl()));
  sl.registerLazySingleton(() => GetAssignmentDetail(sl()));
  sl.registerLazySingleton(() => UpdateAssignment(sl()));
  sl.registerLazySingleton(() => DeleteAssignment(sl()));
  sl.registerLazySingleton(() => PublishAssignment(sl()));
  sl.registerLazySingleton(() => UnpublishAssignment(sl()));
  sl.registerLazySingleton(() => GetAssignmentSubmissions(sl()));
  sl.registerLazySingleton(() => GetAssignmentSubmissionDetail(sl()));
  sl.registerLazySingleton(() => GradeSubmission(sl()));
  sl.registerLazySingleton(() => ReturnSubmission(sl()));
  sl.registerLazySingleton(() => CreateSubmission(sl()));
  sl.registerLazySingleton(() => UploadFile(sl()));
  sl.registerLazySingleton(() => DeleteFile(sl()));
  sl.registerLazySingleton(() => SubmitAssignment(sl()));
  sl.registerLazySingleton(() => DownloadFile(sl()));
  sl.registerLazySingleton(() => ReorderAllAssignments(sl()));
  sl.registerLazySingleton(() => GetStudentAssignmentSubmission(sl()));

  // Learning Material use cases
  sl.registerLazySingleton(() => CreateMaterial(sl()));
  sl.registerLazySingleton(() => GetMaterials(sl()));
  sl.registerLazySingleton(() => GetMaterialDetail(sl()));
  sl.registerLazySingleton(() => UpdateMaterial(sl()));
  sl.registerLazySingleton(() => DeleteMaterial(sl()));
  sl.registerLazySingleton(() => reorder.ReorderMaterial(sl()));
  sl.registerLazySingleton(() => reorder.ReorderAllMaterials(sl()));
  sl.registerLazySingleton(() => material.UploadFile(sl()));
  sl.registerLazySingleton(() => material.DeleteFile(sl()));
  sl.registerLazySingleton(() => material.DownloadFile(sl()));

  // Grading - Repository
  sl.registerLazySingleton<GradingRepository>(
    () => GradingRepositoryImpl(
      remoteDataSource: sl<GradingRemoteDataSource>(),
      localDataSource: sl<GradingLocalDataSource>(),
      syncQueue: sl<SyncQueue>(),
      dataEventBus: sl<DataEventBus>(),
      studentRecordsRepository: sl<StudentRecordsRepository>(),
    ),
  );

  // Grading use cases
  sl.registerLazySingleton(() => GetGradingConfig(sl()));
  sl.registerLazySingleton(() => SetupGrading(sl()));
  sl.registerLazySingleton(() => UpdateGradingConfig(sl()));
  sl.registerLazySingleton(() => GetGradeItems(sl()));
  sl.registerLazySingleton(() => CreateGradeItem(sl()));
  sl.registerLazySingleton(() => UpdateGradeItem(sl()));
  sl.registerLazySingleton(() => DeleteGradeItem(sl()));
  sl.registerLazySingleton(() => GetScoresByItem(sl()));
  sl.registerLazySingleton(() => SaveScores(sl()));
  sl.registerLazySingleton(() => SetScoreOverride(sl()));
  sl.registerLazySingleton(() => ClearScoreOverride(sl()));
  sl.registerLazySingleton(() => GetTermGrades(sl()));
  sl.registerLazySingleton(() => ComputeGrades(sl()));
  sl.registerLazySingleton(() => GetGradeSummary(sl()));
  sl.registerLazySingleton(() => GetFinalGrades(sl()));
  sl.registerLazySingleton(() => UpdateTermGrade(sl()));
  sl.registerLazySingleton(() => GetMyGrades(sl()));
  sl.registerLazySingleton(() => GetMyGradeDetail(sl()));

  // GSA/SF9/SF10 use cases
  sl.registerLazySingleton(() => GetGeneralAverages(sl()));
  sl.registerLazySingleton(() => GetSf9(sl()));
  sl.registerLazySingleton(() => GetSf10(sl()));

  // Score Generation Service
  sl.registerLazySingleton<ScoreGenerationService>(
    () => ScoreGenerationService(
      gradingRepository: sl<GradingRepository>(),
      assessmentRepository: sl<AssessmentRepository>(),
      assignmentRepository: sl<AssignmentRepository>(),
    ),
  );

  // Score Generation use cases
  sl.registerLazySingleton(() => GenerateScores(sl<ScoreGenerationService>()));
  sl.registerLazySingleton(() => HasScoresForGradeItem(sl<ScoreGenerationService>()));
  sl.registerLazySingleton(() => GetScoreSummary(sl<ScoreGenerationService>()));
  
  // Unified read
  sl.registerLazySingleton(() => GetClassGrades(sl<GradingRepository>()));

  // Batch Operations
  sl.registerLazySingleton(() => GetGradeDataBatch(sl<GradingRepository>()));

  // TOS - Repository
  sl.registerLazySingleton<SetupRepository>(
    () => SetupRepositoryImpl(
      remoteDataSource: sl<SetupRemoteDataSource>(),
      localDataSource: sl<SetupLocalDataSource>(),
      syncQueue: sl<SyncQueue>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );
  sl.registerLazySingleton<TosRepository>(
    () => TosRepositoryImpl(
      remoteDataSource: sl<TosRemoteDataSource>(),
      localDataSource: sl<TosLocalDataSource>(),
      syncQueue: sl<SyncQueue>(),
      dataEventBus: sl<DataEventBus>(),
    ),
  );
  sl.registerLazySingleton<DocumentExportRepository>(
    () => DocumentExportRepositoryImpl(sl<DocumentExportRemoteDataSource>()),
  );
  sl.registerLazySingleton<StudentRecordsRepository>(
    () => StudentRecordsRepositoryImpl(
      sl<StudentRecordsRemoteDataSource>(),
      sl<StudentRecordsLocalDataSource>(),
      sl<GradingLocalDataSource>(),
      sl<SyncQueue>(),
      sl<DataEventBus>(),
    ),
  );

  // Setup use cases
  sl.registerLazySingleton(() => GetSchoolDetails(sl()));
  sl.registerLazySingleton(() => UpdateSchoolDetails(sl()));
  sl.registerLazySingleton(() => UpdateSchoolCode(sl()));

  // TOS use cases
  sl.registerLazySingleton(() => GetTosList(sl()));
  sl.registerLazySingleton(() => GetTosDetail(sl()));
  sl.registerLazySingleton(() => CreateTos(sl()));
  sl.registerLazySingleton(() => UpdateTos(sl()));
  sl.registerLazySingleton(() => DeleteTos(sl()));
  sl.registerLazySingleton(() => AddCompetency(sl()));
  sl.registerLazySingleton(() => UpdateCompetency(sl()));
  sl.registerLazySingleton(() => DeleteCompetency(sl()));
  sl.registerLazySingleton(() => BulkAddCompetencies(sl()));
  sl.registerLazySingleton(() => SearchMelcs(sl()));

  // Document Export use cases
  sl.registerLazySingleton(() => ExportClassGrades(sl()));
  sl.registerLazySingleton(() => ExportSf9(sl()));
  sl.registerLazySingleton(() => ExportSf10Pdf(sl()));
  sl.registerLazySingleton(() => ExportSf10Excel(sl()));

  // Student Records use cases
  sl.registerLazySingleton(() => GetLearnerDetails(sl()));
  sl.registerLazySingleton(() => UpsertLearnerDetails(sl()));
  sl.registerLazySingleton(() => GetAttendance(sl()));
  sl.registerLazySingleton(() => UpsertAttendance(sl()));
  sl.registerLazySingleton(() => GetCoreValues(sl()));
  sl.registerLazySingleton(() => UpsertCoreValues(sl()));
  sl.registerLazySingleton(() => GetSf10V2(sl()));
  sl.registerLazySingleton(() => GetSchoolHistory(sl()));
  sl.registerLazySingleton(() => CreateSchoolHistory(sl()));
  sl.registerLazySingleton(() => UpdateSchoolHistory(sl()));
  sl.registerLazySingleton(() => DeleteSchoolHistory(sl()));
  sl.registerLazySingleton(() => GetPreviousSubjects(sl()));
  sl.registerLazySingleton(() => UpsertPreviousSubject(sl()));
  sl.registerLazySingleton(() => GetPreviousAttendance(sl()));
  sl.registerLazySingleton(() => UpsertPreviousAttendance(sl()));
}
