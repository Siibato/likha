use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;
use crate::services::grading::GradingService;

impl super::AssessmentService {
    pub async fn get_submissions(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionListResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self.submission_repo
            .find_by_assessment_id(assessment_id).await?;

        let mut responses = Vec::new();
        for s in submissions {
            let student = self.user_repo.find_by_id(s.user_id).await?
                .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

            responses.push(SubmissionSummaryResponse {
                id: s.id,
                student_id: s.user_id,
                student_name: student.full_name,
                student_username: student.username,
                started_at: s.started_at.to_string(),
                submitted_at: s.submitted_at.map(|dt| dt.to_string()),
                total_points: s.total_points,
            });
        }

        Ok(SubmissionListResponse { submissions: responses })
    }

    pub async fn get_submission_detail(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionDetailResponse> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let student = self.user_repo.find_by_id(submission.user_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        let answers = self.submission_repo
            .find_answers_by_submission_id(submission_id).await?;

        let mut answer_responses = Vec::new();
        for a in answers {
            let question = self.assessment_repo.find_question_by_id(a.question_id).await?;
            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let selected_choices = if question.question_type == "multiple_choice" {
                let selection_ids = self.submission_repo.find_answer_choices(a.id).await?;
                let mut choice_responses = Vec::new();
                let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                for choice_id in selection_ids {
                    if let Some(choice) = choices.iter().find(|c| c.id == choice_id) {
                        choice_responses.push(SelectedChoiceResponse {
                            choice_id: choice.id,
                            choice_text: choice.choice_text.clone(),
                            is_correct: choice.is_correct,
                        });
                    }
                }
                Some(choice_responses)
            } else {
                None
            };

            let enumeration_answers = if question.question_type == "enumeration" {
                let enum_texts = self.submission_repo.find_enumeration_answers(a.id).await?;
                Some(
                    enum_texts.into_iter().map(|answer_text| EnumerationAnswerResponse {
                        answer_text,
                    }).collect()
                )
            } else {
                None
            };

            answer_responses.push(SubmissionAnswerResponse {
                id: a.id,
                question_id: a.question_id,
                question_text: question.question_text,
                question_type: question.question_type,
                question_points: question.points,
                selected_choices,
                enumeration_answers,
                points_earned: a.points,
                overridden_by: a.overridden_by,
                overridden_at: a.overridden_at.map(|dt| dt.to_string()),
            });
        }

        Ok(SubmissionDetailResponse {
            id: submission.id,
            assessment_id: submission.assessment_id,
            student_id: submission.user_id,
            student_name: student.full_name,
            started_at: submission.started_at.to_string(),
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            total_points: submission.total_points,
            answers: answer_responses,
        })
    }

    pub async fn override_answer(
        &self,
        answer_id: Uuid,
        request: OverrideAnswerRequest,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionAnswerResponse> {
        let answer = self.submission_repo.find_answer_by_id(answer_id).await?
            .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?;

        let submission = self.submission_repo.find_by_id(answer.submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let question = self.assessment_repo.find_question_by_id(answer.question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        let points = if request.is_correct { question.points as f64 } else { 0.0 };

        let updated = self.submission_repo
            .override_answer(answer_id, request.is_correct, points)
            .await?;

        GradingService::recalculate_final_score(submission.id, &self.submission_repo).await?;

        Ok(SubmissionAnswerResponse {
            id: updated.id,
            question_id: updated.question_id,
            question_text: question.question_text,
            question_type: question.question_type,
            question_points: question.points,
            selected_choices: None,
            enumeration_answers: None,
            points_earned: updated.points,
            overridden_by: updated.overridden_by,
            overridden_at: updated.overridden_at.map(|dt| dt.to_string()),
        })
    }

    pub async fn get_student_assessment_submissions(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<StudentAssessmentSubmissionsResponse> {
        // 1. Auth: teacher must own this class
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Teacher access required".to_string()));
        }

        // 2. Fetch all published assessments in this class
        let assessments = self.assessment_repo.find_published_by_class_id(class_id).await?;

        // 3. For each assessment, look up the student's submission (may be None)
        let mut items = Vec::new();
        for assessment in assessments {
            if let Some(sub) = self.submission_repo
                .find_by_student_and_assessment(student_id, assessment.id).await? {
                let student = self.user_repo.find_by_id(sub.user_id).await?
                    .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;
                items.push(StudentAssessmentSubmissionItem {
                    assessment_id: assessment.id,
                    id: sub.id,
                    student_id: sub.user_id,
                    student_name: student.full_name.clone(),
                    student_username: student.username.clone(),
                    started_at: sub.started_at.to_string(),
                    submitted_at: sub.submitted_at.map(|dt| dt.to_string()),
                    total_points: sub.total_points,
                });
            }
        }

        Ok(StudentAssessmentSubmissionsResponse { submissions: items })
    }
}