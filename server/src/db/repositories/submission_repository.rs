use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{
    assessment_submissions, submission_answer_items, submission_answers,
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
            user_id: Set(student_id),
            started_at: Set(Utc::now().naive_utc()),
            submitted_at: Set(None),
            total_points: Set(0),
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
            .filter(assessment_submissions::Column::UserId.eq(student_id))
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
            .filter(assessment_submissions::Column::SubmittedAt.is_not_null())
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
        _answer_text: Option<String>,
    ) -> AppResult<submission_answers::Model> {
        let existing = submission_answers::Entity::find()
            .filter(submission_answers::Column::SubmissionId.eq(submission_id))
            .filter(submission_answers::Column::QuestionId.eq(question_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(existing) = existing {
            // No need to update - answer_text is stored in submission_answer_items instead
            Ok(existing)
        } else {
            let answer = submission_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                submission_id: Set(submission_id),
                question_id: Set(question_id),
                points: Set(0.0),
                overridden_by: Set(None),
                overridden_at: Set(None),
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
        _is_auto_correct: Option<bool>,
        points_awarded: f64,
    ) -> AppResult<submission_answers::Model> {
        let mut answer: submission_answers::ActiveModel =
            submission_answers::Entity::find_by_id(answer_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?
                .into();

        answer.points = Set(points_awarded);

        answer
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update answer grade: {}", e)))
    }

    pub async fn override_answer(
        &self,
        answer_id: Uuid,
        _is_correct: bool,
        points: f64,
    ) -> AppResult<submission_answers::Model> {
        let mut answer: submission_answers::ActiveModel =
            submission_answers::Entity::find_by_id(answer_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?
                .into();

        answer.points = Set(points);
        answer.overridden_by = Set(None); // Would be set by the caller if needed
        answer.overridden_at = Set(Some(Utc::now().naive_utc()));

        answer
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to override answer: {}", e)))
    }

    pub async fn update_submission_scores(
        &self,
        submission_id: Uuid,
        total_points: i32,
    ) -> AppResult<()> {
        let mut submission: assessment_submissions::ActiveModel =
            assessment_submissions::Entity::find_by_id(submission_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.total_points = Set(total_points);

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

        let now = Utc::now().naive_utc();
        submission.submitted_at = Set(Some(now));

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to submit: {}", e)))
    }

    // ===== ANSWER ITEMS (submission_answer_items) =====

    pub async fn save_answer_items(
        &self,
        submission_answer_id: Uuid,
        items: Vec<(Option<Uuid>, Option<Uuid>, Option<String>, bool)>, // (answer_key_id, choice_id, answer_text, is_correct)
    ) -> AppResult<()> {
        // Delete existing items
        submission_answer_items::Entity::delete_many()
            .filter(submission_answer_items::Column::SubmissionAnswerId.eq(submission_answer_id))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear answer items: {}", e)))?;

        // Insert new items
        for (answer_key_id, choice_id, answer_text, is_correct) in items {
            let item = submission_answer_items::ActiveModel {
                id: Set(Uuid::new_v4()),
                submission_answer_id: Set(submission_answer_id),
                answer_key_id: Set(answer_key_id),
                choice_id: Set(choice_id),
                answer_text: Set(answer_text),
                is_correct: Set(is_correct),
            };
            item.insert(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to save answer item: {}", e)))?;
        }

        Ok(())
    }

    pub async fn find_answer_items_by_submission_answer_id(
        &self,
        submission_answer_id: Uuid,
    ) -> AppResult<Vec<submission_answer_items::Model>> {
        submission_answer_items::Entity::find()
            .filter(submission_answer_items::Column::SubmissionAnswerId.eq(submission_answer_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    /// Save answer choices - wraps save_answer_items for backward compatibility
    pub async fn save_answer_choices(
        &self,
        submission_answer_id: Uuid,
        choice_ids: Vec<Uuid>,
    ) -> AppResult<()> {
        let items = choice_ids.into_iter()
            .map(|choice_id| (None, Some(choice_id), None, false))
            .collect();
        self.save_answer_items(submission_answer_id, items).await
    }

    /// Save enumeration answers - wraps save_answer_items for backward compatibility
    pub async fn save_enumeration_answers(
        &self,
        submission_answer_id: Uuid,
        enum_answers: Vec<String>,
    ) -> AppResult<()> {
        let items = enum_answers.into_iter()
            .map(|answer_text| (None, None, Some(answer_text), false))
            .collect();
        self.save_answer_items(submission_answer_id, items).await
    }

    /// Find answer choices - returns choice IDs for an answer
    pub async fn find_answer_choices(
        &self,
        submission_answer_id: Uuid,
    ) -> AppResult<Vec<Uuid>> {
        let items = self.find_answer_items_by_submission_answer_id(submission_answer_id).await?;
        Ok(items.into_iter()
            .filter_map(|item| item.choice_id)
            .collect())
    }

    /// Find enumeration answers - returns answer texts for an answer
    pub async fn find_enumeration_answers(
        &self,
        submission_answer_id: Uuid,
    ) -> AppResult<Vec<String>> {
        let items = self.find_answer_items_by_submission_answer_id(submission_answer_id).await?;
        Ok(items.into_iter()
            .filter_map(|item| item.answer_text)
            .collect())
    }
}
