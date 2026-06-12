import 'package:dartz/dartz.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';

ResultFuture<StartSubmissionResult> startAssessment(
  AssessmentRepositoryBase base, {
  required String assessmentId,
  required String studentId,
  required String studentName,
  required String studentUsername,
}) async {
  try {
    RepoLogger.instance.log('startAssessment() - assessmentId: $assessmentId, studentId: $studentId, serverReachable: ${base.serverReachabilityService.isServerReachable}');

    if (!base.serverReachabilityService.isServerReachable) {
      RepoLogger.instance.log('startAssessment() - OFFLINE PATH');
      try {
        final existingSubmission = await base.localDataSource.getCachedStudentSubmission(
          assessmentId,
          studentId,
        );
        RepoLogger.instance.log('startAssessment() - existingSubmission: $existingSubmission');

        if (existingSubmission != null && !existingSubmission.isSubmitted) {
          RepoLogger.instance.log('startAssessment() - RESUMING EXISTING SUBMISSION ${existingSubmission.id}');
          final (_, questions) =
              await base.localDataSource.getCachedAssessmentDetail(assessmentId);
          final questionMaps = questions.map((q) => {
            'id': q.id,
            'question_type': q.questionType,
            'question_text': q.questionText,
            'points': q.points,
            'order_index': q.orderIndex,
            'is_multi_select': q.isMultiSelect,
            if (q.choices != null)
              'choices': q.choices!
                  .map((c) => {
                        'id': c.id,
                        'choice_text': c.choiceText,
                        'order_index': c.orderIndex,
                      })
                  .toList(),
            if (q.enumerationItems != null)
              'enumeration_count': q.enumerationItems!.length,
          }).toList();
          return Right(StartSubmissionResult(
            submissionId: existingSubmission.id,
            startedAt: existingSubmission.startedAt,
            questions: questionMaps,
          ));
        }

        RepoLogger.instance.log('startAssessment() - CREATING NEW OFFLINE SUBMISSION');
        final (_, questions) =
            await base.localDataSource.getCachedAssessmentDetail(assessmentId);
        final localId = await base.localDataSource.startAssessment(
          assessmentId: assessmentId,
          studentId: studentId,
          studentName: studentName,
          studentUsername: studentUsername,
        );

        final questionMaps = questions.map((q) => {
          'id': q.id,
          'question_type': q.questionType,
          'question_text': q.questionText,
          'points': q.points,
          'order_index': q.orderIndex,
          'is_multi_select': q.isMultiSelect,
          if (q.choices != null)
            'choices': q.choices!
                .map((c) => {
                      'id': c.id,
                      'choice_text': c.choiceText,
                      'order_index': c.orderIndex,
                    })
                .toList(),
          if (q.enumerationItems != null)
            'enumeration_count': q.enumerationItems!.length,
        }).toList();

        return Right(StartSubmissionResult(
          submissionId: localId,
          startedAt: DateTime.now(),
          questions: questionMaps,
        ));
      } on CacheException catch (e) {
        RepoLogger.instance.error('startAssessment() OFFLINE ERROR', e);
        return Left(
            CacheFailure('Assessment not available offline: ${e.message}'));
      }
    }

    RepoLogger.instance.log('startAssessment() - ONLINE PATH - STARTING');

    final existingSubmission = await base.localDataSource.getCachedStudentSubmission(
      assessmentId,
      studentId,
    );
    RepoLogger.instance.log('startAssessment() - ONLINE PATH - existingSubmission: $existingSubmission');

    if (existingSubmission != null && !existingSubmission.isSubmitted) {
      RepoLogger.instance.log('startAssessment() - ONLINE PATH - RESUMING EXISTING SUBMISSION ${existingSubmission.id}');
      final (_, questions) =
          await base.localDataSource.getCachedAssessmentDetail(assessmentId);
      final questionMaps = questions.map((q) => {
        'id': q.id,
        'question_type': q.questionType,
        'question_text': q.questionText,
        'points': q.points,
        'order_index': q.orderIndex,
        'is_multi_select': q.isMultiSelect,
        if (q.choices != null)
          'choices': q.choices!
              .map((c) => {
                    'id': c.id,
                    'choice_text': c.choiceText,
                    'order_index': c.orderIndex,
                  })
              .toList(),
        if (q.enumerationItems != null)
          'enumeration_count': q.enumerationItems!.length,
      }).toList();
      return Right(StartSubmissionResult(
        submissionId: existingSubmission.id,
        startedAt: existingSubmission.startedAt,
        questions: questionMaps,
      ));
    }

    if (existingSubmission != null && existingSubmission.isSubmitted) {
      RepoLogger.instance.log('startAssessment() - ONLINE PATH - SUBMISSION ALREADY SUBMITTED');
      return const Left(ServerFailure('Assessment already submitted'));
    }

    RepoLogger.instance.log('startAssessment() - ONLINE PATH - NO EXISTING SUBMISSION, CALLING SERVER');
    final result =
        await base.remoteDataSource.startAssessment(assessmentId: assessmentId);
    RepoLogger.instance.log('startAssessment() - ONLINE SUCCESS - submissionId: ${result.submissionId}');

    await base.localDataSource.cacheStartSubmissionResult(
      submissionId: result.submissionId,
      assessmentId: assessmentId,
      studentId: studentId,
      studentName: studentName,
      studentUsername: studentUsername,
      startedAt: result.startedAt,
    );

    return Right(result);
  } on ServerException catch (e) {
    RepoLogger.instance.error('startAssessment() SERVER ERROR', e);
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    RepoLogger.instance.error('startAssessment() NETWORK ERROR', e);
    return Left(NetworkFailure(e.message));
  } catch (e) {
    RepoLogger.instance.error('startAssessment() UNEXPECTED ERROR', e);
    return Left(ServerFailure(e.toString()));
  }
}
