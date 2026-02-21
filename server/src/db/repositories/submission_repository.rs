use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{
    assessment_submissions, submission_answer_choices, submission_answers,
    submission_enumeration_answers,
};
use crate::utils::{AppError, AppResult};

pub struct SubmissionRepository {
    db: DatabaseConnection,
}

impl SubmissionRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_submission(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<assessment_submissions::Model> {
        let submission = assessment_submissions::ActiveModel {
            id: Set(Uuid::new_v4()),
            assessment_id: Set(assessment_id),
            student_id: Set(student_id),
            started_at: Set(Utc::now().naive_utc()),
            submitted_at: Set(None),
            auto_score: Set(0.0),
            final_score: Set(0.0),
            is_submitted: Set(false),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
        };

        submission
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create submission: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<assessment_submissions::Model>> {
        assessment_submissions::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_assessment_id(
        &self,
        assessment_id: Uuid,
    ) -> AppResult<Vec<assessment_submissions::Model>> {
        assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
            .order_by_desc(assessment_submissions::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_student_and_assessment(
        &self,
        student_id: Uuid,
        assessment_id: Uuid,
    ) -> AppResult<Option<assessment_submissions::Model>> {
        assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::StudentId.eq(student_id))
            .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn count_by_assessment_id(&self, assessment_id: Uuid) -> AppResult<usize> {
        let count = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        Ok(count as usize)
    }

    pub async fn count_submitted_by_assessment_id(&self, assessment_id: Uuid) -> AppResult<usize> {
        let count = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::AssessmentId.eq(assessment_id))
            .filter(assessment_submissions::Column::IsSubmitted.eq(true))
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        Ok(count as usize)
    }

    // ===== SUBMISSION ANSWERS =====

    pub async fn upsert_answer(
        &self,
        submission_id: Uuid,
        question_id: Uuid,
        answer_text: Option<String>,
    ) -> AppResult<submission_answers::Model> {
        let existing = submission_answers::Entity::find()
            .filter(submission_answers::Column::SubmissionId.eq(submission_id))
            .filter(submission_answers::Column::QuestionId.eq(question_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(existing) = existing {
            let mut active: submission_answers::ActiveModel = existing.into();
            active.answer_text = Set(answer_text);
            active
                .update(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to update answer: {}", e)))
        } else {
            let answer = submission_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                submission_id: Set(submission_id),
                question_id: Set(question_id),
                answer_text: Set(answer_text),
                is_auto_correct: Set(None),
                is_override_correct: Set(None),
                points_awarded: Set(0.0),
            };

            answer
                .insert(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to save answer: {}", e)))
        }
    }

    pub async fn find_answers_by_submission_id(
        &self,
        submission_id: Uuid,
    ) -> AppResult<Vec<submission_answers::Model>> {
        submission_answers::Entity::find()
            .filter(submission_answers::Column::SubmissionId.eq(submission_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_answer_by_id(&self, id: Uuid) -> AppResult<Option<submission_answers::Model>> {
        submission_answers::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_answer_grade(
        &self,
        answer_id: Uuid,
        is_auto_correct: Option<bool>,
        points_awarded: f64,
    ) -> AppResult<submission_answers::Model> {
        let mut answer: submission_answers::ActiveModel =
            submission_answers::Entity::find_by_id(answer_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?
                .into();

        answer.is_auto_correct = Set(is_auto_correct);
        answer.points_awarded = Set(points_awarded);

        answer
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update answer grade: {}", e)))
    }

    pub async fn override_answer(
        &self,
        answer_id: Uuid,
        is_correct: bool,
        points: f64,
    ) -> AppResult<submission_answers::Model> {
        let mut answer: submission_answers::ActiveModel =
            submission_answers::Entity::find_by_id(answer_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?
                .into();

        answer.is_override_correct = Set(Some(is_correct));
        answer.points_awarded = Set(points);

        answer
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to override answer: {}", e)))
    }

    pub async fn update_submission_scores(
        &self,
        submission_id: Uuid,
        auto_score: f64,
        final_score: f64,
    ) -> AppResult<()> {
        let mut submission: assessment_submissions::ActiveModel =
            assessment_submissions::Entity::find_by_id(submission_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.auto_score = Set(auto_score);
        submission.final_score = Set(final_score);

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update scores: {}", e)))?;

        Ok(())
    }

    pub async fn mark_submitted(&self, submission_id: Uuid) -> AppResult<assessment_submissions::Model> {
        let mut submission: assessment_submissions::ActiveModel =
            assessment_submissions::Entity::find_by_id(submission_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.is_submitted = Set(true);
        submission.submitted_at = Set(Some(Utc::now().naive_utc()));

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to submit: {}", e)))
    }

    // ===== ANSWER CHOICES (MC selections) =====

    pub async fn save_answer_choices(
        &self,
        submission_answer_id: Uuid,
        choice_ids: Vec<Uuid>,
    ) -> AppResult<()> {
        // Delete existing selections
        submission_answer_choices::Entity::delete_many()
            .filter(submission_answer_choices::Column::SubmissionAnswerId.eq(submission_answer_id))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear choices: {}", e)))?;

        // Insert new selections
        for choice_id in choice_ids {
            let selection = submission_answer_choices::ActiveModel {
                id: Set(Uuid::new_v4()),
                submission_answer_id: Set(submission_answer_id),
                choice_id: Set(choice_id),
            };
            selection
                .insert(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to save choice: {}", e)))?;
        }

        Ok(())
    }

    pub async fn find_answer_choices(
        &self,
        submission_answer_id: Uuid,
    ) -> AppResult<Vec<submission_answer_choices::Model>> {
        submission_answer_choices::Entity::find()
            .filter(submission_answer_choices::Column::SubmissionAnswerId.eq(submission_answer_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    // ===== ENUMERATION ANSWERS =====

    pub async fn save_enumeration_answers(
        &self,
        submission_answer_id: Uuid,
        answers: Vec<String>,
    ) -> AppResult<()> {
        // Delete existing
        submission_enumeration_answers::Entity::delete_many()
            .filter(submission_enumeration_answers::Column::SubmissionAnswerId.eq(submission_answer_id))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear enum answers: {}", e)))?;

        // Insert new
        for answer_text in answers {
            let answer = submission_enumeration_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                submission_answer_id: Set(submission_answer_id),
                answer_text: Set(answer_text),
                matched_item_id: Set(None),
                is_auto_correct: Set(None),
                is_override_correct: Set(None),
            };
            answer
                .insert(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to save enum answer: {}", e)))?;
        }

        Ok(())
    }

    pub async fn find_enumeration_answers(
        &self,
        submission_answer_id: Uuid,
    ) -> AppResult<Vec<submission_enumeration_answers::Model>> {
        submission_enumeration_answers::Entity::find()
            .filter(submission_enumeration_answers::Column::SubmissionAnswerId.eq(submission_answer_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_enumeration_answer_grade(
        &self,
        id: Uuid,
        matched_item_id: Option<Uuid>,
        is_auto_correct: bool,
    ) -> AppResult<()> {
        let mut answer: submission_enumeration_answers::ActiveModel =
            submission_enumeration_answers::Entity::find_by_id(id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Enumeration answer not found".to_string()))?
                .into();

        answer.matched_item_id = Set(matched_item_id);
        answer.is_auto_correct = Set(Some(is_auto_correct));

        answer
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update enum answer: {}", e)))?;

        Ok(())
    }
}
