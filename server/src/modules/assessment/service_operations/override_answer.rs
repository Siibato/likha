use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;
use crate::modules::grading::helpers::auto_populate;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn override_answer(
        &self,
        answer_id: Uuid,
        request: OverrideAnswerRequest,
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

        let points = request.points.unwrap_or_else(|| {
            if request.is_correct { question.points as f64 } else { 0.0 }
        });

        let updated = self.assessment_repo
            .override_answer(answer_id, request.is_correct, points)
            .await?;

        let final_score = self.recalculate_final_score(submission.id).await?;

        let grade_item_id = auto_populate::auto_populate_score(
            &self.grade_computation_repo, "assessment", submission.assessment_id, submission.user_id, final_score,
        ).await?;

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_assessment_submissions(submission.assessment_id).await;
            inv.invalidate_assessment_submission_detail(submission.id).await;
            inv.invalidate_student_results(submission.id).await;
            inv.invalidate_assessment_student_submission(submission.assessment_id, submission.user_id).await;
            if let Some(period) = assessment.grading_period_number {
                inv.invalidate_class_grades(assessment.class_id, period).await;
                inv.invalidate_student_grades(assessment.class_id, submission.user_id, period).await;
            }
            if let Some(item_id) = grade_item_id {
                inv.invalidate_item_scores(item_id).await;
            }
        }

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
