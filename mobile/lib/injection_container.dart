import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/domain/assessments/data/datasources/assessment_remote_datasource.dart';
import 'package:likha/domain/assessments/data/repositories/assessment_repository_impl.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/delete_assessment.dart';
import 'package:likha/domain/assessments/usecases/get_assessment_detail.dart';
import 'package:likha/domain/assessments/usecases/get_assessments.dart';
import 'package:likha/domain/assessments/usecases/get_statistics.dart';
import 'package:likha/domain/assessments/usecases/get_student_results.dart';
import 'package:likha/domain/assessments/usecases/get_submission_detail.dart';
import 'package:likha/domain/assessments/usecases/get_submissions.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/domain/assessments/usecases/publish_assessment.dart';
import 'package:likha/domain/assessments/usecases/release_results.dart';
import 'package:likha/domain/assessments/usecases/save_answers.dart';
import 'package:likha/domain/assessments/usecases/start_assessment.dart';
import 'package:likha/domain/assessments/usecases/submit_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/domain/assessments/usecases/delete_question.dart';
import 'package:likha/domain/assignments/data/datasources/assignment_remote_datasource.dart';
import 'package:likha/domain/assignments/data/repositories/assignment_repository_impl.dart';
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
import 'package:likha/domain/assignments/usecases/return_submission.dart';
import 'package:likha/domain/assignments/usecases/submit_assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/domain/auth/data/datasources/auth_remote_datasource.dart';
import 'package:likha/domain/auth/data/repositories/auth_repository_impl.dart';
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
import 'package:likha/domain/classes/data/datasources/class_remote_datasource.dart';
import 'package:likha/domain/classes/data/repositories/class_repository_impl.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';
import 'package:likha/domain/classes/usecases/add_student.dart';
import 'package:likha/domain/classes/usecases/create_class.dart';
import 'package:likha/domain/classes/usecases/get_class_detail.dart';
import 'package:likha/domain/classes/usecases/get_my_classes.dart';
import 'package:likha/domain/classes/usecases/remove_student.dart';
import 'package:likha/domain/classes/usecases/search_students.dart';
import 'package:likha/domain/classes/usecases/update_class.dart';
import 'package:likha/domain/learning_materials/data/datasources/learning_material_remote_datasource.dart';
import 'package:likha/domain/learning_materials/data/repositories/learning_material_repository_impl.dart';
import 'package:likha/domain/learning_materials/repositories/learning_material_repository.dart';
import 'package:likha/domain/learning_materials/usecases/create_material.dart';
import 'package:likha/domain/learning_materials/usecases/delete_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/delete_material.dart';
import 'package:likha/domain/learning_materials/usecases/download_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/get_material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/get_materials.dart';
import 'package:likha/domain/learning_materials/usecases/reorder_material.dart';
import 'package:likha/domain/learning_materials/usecases/update_material.dart';
import 'package:likha/domain/learning_materials/usecases/upload_file.dart' as material;
import 'package:likha/services/storage_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  sl.registerLazySingleton(() => secureStorage);

  // Core
  sl.registerLazySingleton(() => StorageService(sl()));
  sl.registerLazySingleton(() => DioClient(sl()));

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ClassRemoteDataSource>(
    () => ClassRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AssessmentRemoteDataSource>(
    () => AssessmentRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AssignmentRemoteDataSource>(
    () => AssignmentRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<LearningMaterialRemoteDataSource>(
    () => LearningMaterialRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ClassRepository>(
    () => ClassRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AssessmentRepository>(
    () => AssessmentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AssignmentRepository>(
    () => AssignmentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<LearningMaterialRepository>(
    () => LearningMaterialRepositoryImpl(sl()),
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

  // Class use cases
  sl.registerLazySingleton(() => CreateClass(sl()));
  sl.registerLazySingleton(() => GetMyClasses(sl()));
  sl.registerLazySingleton(() => GetClassDetail(sl()));
  sl.registerLazySingleton(() => UpdateClass(sl()));
  sl.registerLazySingleton(() => AddStudent(sl()));
  sl.registerLazySingleton(() => RemoveStudent(sl()));
  sl.registerLazySingleton(() => SearchStudents(sl()));

  // Assessment use cases
  sl.registerLazySingleton(() => CreateAssessment(sl()));
  sl.registerLazySingleton(() => GetAssessments(sl()));
  sl.registerLazySingleton(() => GetAssessmentDetail(sl()));
  sl.registerLazySingleton(() => PublishAssessment(sl()));
  sl.registerLazySingleton(() => DeleteAssessment(sl()));
  sl.registerLazySingleton(() => AddQuestions(sl()));
  sl.registerLazySingleton(() => GetSubmissions(sl()));
  sl.registerLazySingleton(() => GetSubmissionDetail(sl()));
  sl.registerLazySingleton(() => OverrideAnswer(sl()));
  sl.registerLazySingleton(() => ReleaseResults(sl()));
  sl.registerLazySingleton(() => GetStatistics(sl()));
  sl.registerLazySingleton(() => StartAssessment(sl()));
  sl.registerLazySingleton(() => SaveAnswers(sl()));
  sl.registerLazySingleton(() => SubmitAssessment(sl()));
  sl.registerLazySingleton(() => GetStudentResults(sl()));
  sl.registerLazySingleton(() => UpdateAssessment(sl()));
  sl.registerLazySingleton(() => UpdateQuestion(sl()));
  sl.registerLazySingleton(() => DeleteQuestion(sl()));

  // Assignment use cases
  sl.registerLazySingleton(() => CreateAssignment(sl()));
  sl.registerLazySingleton(() => GetAssignments(sl()));
  sl.registerLazySingleton(() => GetAssignmentDetail(sl()));
  sl.registerLazySingleton(() => UpdateAssignment(sl()));
  sl.registerLazySingleton(() => DeleteAssignment(sl()));
  sl.registerLazySingleton(() => PublishAssignment(sl()));
  sl.registerLazySingleton(() => GetAssignmentSubmissions(sl()));
  sl.registerLazySingleton(() => GetAssignmentSubmissionDetail(sl()));
  sl.registerLazySingleton(() => GradeSubmission(sl()));
  sl.registerLazySingleton(() => ReturnSubmission(sl()));
  sl.registerLazySingleton(() => CreateSubmission(sl()));
  sl.registerLazySingleton(() => UploadFile(sl()));
  sl.registerLazySingleton(() => DeleteFile(sl()));
  sl.registerLazySingleton(() => SubmitAssignment(sl()));
  sl.registerLazySingleton(() => DownloadFile(sl()));

  // Learning Material use cases
  sl.registerLazySingleton(() => CreateMaterial(sl()));
  sl.registerLazySingleton(() => GetMaterials(sl()));
  sl.registerLazySingleton(() => GetMaterialDetail(sl()));
  sl.registerLazySingleton(() => UpdateMaterial(sl()));
  sl.registerLazySingleton(() => DeleteMaterial(sl()));
  sl.registerLazySingleton(() => ReorderMaterial(sl()));
  sl.registerLazySingleton(() => material.UploadFile(sl()));
  sl.registerLazySingleton(() => material.DeleteFile(sl()));
  sl.registerLazySingleton(() => material.DownloadFile(sl()));
}
