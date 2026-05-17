use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;
use crate::services::grade_computation::auto_populate;

impl crate::services::assessment::AssessmentService {
    pub async fn grade_essay_answer(
        &self,
        answer_id: Uuid,
        request: GradeEssayRequest,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionAnswerResponse> {
        let answer = self.assessment_repo.find_answer_by_id(answer_id).await?
            .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?;

        let submission = self.assessment_repo.find_submission_by_id(answer.submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let question = self.assessment_repo.find_question_by_id(answer.question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        if question.question_type != "essay" {
            return Err(AppError::BadRequest("This endpoint is only for essay questions".to_string()));
        }

        let max_points = question.points as f64;
        if request.points < 0.0 || request.points > max_points {
            return Err(AppError::BadRequest(format!(
                "Points must be between 0 and {}",
                question.points
            )));
        }

        let is_correct = request.points >= max_points;

        let updated = self.assessment_repo
            .override_answer(answer_id, is_correct, request.points)
            .await?;

        let final_score = self.grading_service.recalculate_final_score(submission.id).await?;

        let _ = auto_populate::auto_populate_score(
            &self.db, "assessment", submission.assessment_id, submission.user_id, final_score,
        ).await;

        Ok(SubmissionAnswerResponse {
            id: updated.id,
            question_id: updated.question_id,
            question_text: question.question_text,
            question_type: question.question_type,
            question_points: question.points,
            answer_text: None,
            selected_choices: None,
            enumeration_answers: None,
            points_earned: updated.points,
            overridden_by: updated.overridden_by,
            overridden_at: updated.overridden_at.map(|dt| dt.to_string()),
            is_pending_essay_grade: false,
        })
    }
}
