use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;
use crate::services::grading::GradingService;

impl super::AssessmentService {
    pub async fn start_assessment(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<StartSubmissionResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        if !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        let now = chrono::Utc::now().naive_utc();
        if now < assessment.open_at {
            return Err(AppError::BadRequest("Assessment is not yet open".to_string()));
        }
        if now > assessment.close_at {
            return Err(AppError::BadRequest("Assessment is closed".to_string()));
        }

        let enrolled = self.class_repo
            .is_student_enrolled(assessment.class_id, student_id).await?;
        if !enrolled {
            return Err(AppError::Forbidden("You are not enrolled in this class".to_string()));
        }

        let existing = self.submission_repo
            .find_by_student_and_assessment(student_id, assessment_id).await?;
        if existing.is_some() {
            return Err(AppError::BadRequest("You have already started this assessment".to_string()));
        }

        let submission = self.submission_repo
            .create_submission(assessment_id, student_id).await?;

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut student_questions = Vec::new();
        for q in questions {
            let choices = if q.question_type == "multiple_choice" {
                let choices = self.assessment_repo
                    .find_choices_by_question_id(q.id).await?;
                Some(
                    choices.into_iter().map(|c| StudentChoiceResponse {
                        id: c.id,
                        choice_text: c.choice_text,
                        order_index: c.order_index,
                    }).collect()
                )
            } else {
                None
            };

            let enumeration_count = if q.question_type == "enumeration" {
                let items = self.assessment_repo
                    .find_enumeration_items_by_question_id(q.id).await?;
                Some(items.len())
            } else {
                None
            };

            student_questions.push(StudentQuestionResponse {
                id: q.id,
                question_type: q.question_type,
                question_text: q.question_text,
                points: q.points,
                order_index: q.order_index,
                is_multi_select: q.is_multi_select,
                choices,
                enumeration_count,
            });
        }

        Ok(StartSubmissionResponse {
            submission_id: submission.id,
            started_at: submission.started_at.to_string(),
            questions: student_questions,
        })
    }

    pub async fn save_answers(
        &self,
        submission_id: Uuid,
        request: SaveAnswersRequest,
        student_id: Uuid,
    ) -> AppResult<()> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.is_submitted {
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        for answer_input in request.answers {
            let answer = self.submission_repo
                .upsert_answer(submission_id, answer_input.question_id, answer_input.answer_text)
                .await?;

            if let Some(choice_ids) = answer_input.selected_choice_ids {
                self.submission_repo
                    .save_answer_choices(answer.id, choice_ids)
                    .await?;
            }

            if let Some(enum_answers) = answer_input.enumeration_answers {
                self.submission_repo
                    .save_enumeration_answers(answer.id, enum_answers)
                    .await?;
            }
        }

        Ok(())
    }

    pub async fn submit_assessment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<SubmissionSummaryResponse> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.is_submitted {
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        let (auto_score, final_score) = GradingService::grade_submission(
            submission_id,
            &self.assessment_repo,
            &self.submission_repo,
        ).await?;

        let submitted = self.submission_repo.mark_submitted(submission_id).await?;

        let student = self.user_repo.find_by_id(student_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        Ok(SubmissionSummaryResponse {
            id: submitted.id,
            student_id: submitted.student_id,
            student_name: student.full_name,
            student_username: student.username,
            started_at: submitted.started_at.to_string(),
            submitted_at: submitted.submitted_at.map(|dt| dt.to_string()),
            auto_score,
            final_score,
            is_submitted: submitted.is_submitted,
        })
    }
}