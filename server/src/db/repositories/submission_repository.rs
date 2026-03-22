use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{
    assessment_submissions, submission_answer_items, submission_answers,
};
use crate::utils::{AppError, AppResult};

/// Per-row data from the batch answer details query for item analysis
#[derive(Debug)]
pub struct AnswerDetail {
    pub student_id: Uuid,
    pub submission_total_points: f64,
    pub question_id: Uuid,
    pub answer_points: f64,
    pub choice_id: Option<Uuid>,
    pub item_is_correct: bool,
}

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
        submission_id: Option<Uuid>,
    ) -> AppResult<assessment_submissions::Model> {
        let submission = assessment_submissions::ActiveModel {
            id: Set(submission_id.unwrap_or_else(Uuid::new_v4)),
            assessment_id: Set(assessment_id),
            user_id: Set(student_id),
            started_at: Set(Utc::now().naive_utc()),
            submitted_at: Set(None),
            total_points: Set(0.0),
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
        total_points: f64,
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

    /// Save answer text for identification questions
    pub async fn save_answer_text(
        &self,
        submission_answer_id: Uuid,
        answer_text: String,
    ) -> AppResult<()> {
        let items = vec![(None, None, Some(answer_text), false)];
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

    /// Save enumeration answers with answer_key_id links to specific slots
    pub async fn save_enumeration_answers_linked(
        &self,
        submission_answer_id: Uuid,
        items: Vec<(Option<Uuid>, String)>, // (answer_key_id, answer_text)
    ) -> AppResult<()> {
        let mapped = items.into_iter()
            .map(|(key_id, text)| (key_id, None, Some(text), false))
            .collect();
        self.save_answer_items(submission_answer_id, mapped).await
    }

    /// Find enumeration answer items - returns full models with is_correct (for enumeration/identification)
    pub async fn find_enumeration_answer_items(
        &self,
        submission_answer_id: Uuid,
    ) -> AppResult<Vec<submission_answer_items::Model>> {
        let items = self.find_answer_items_by_submission_answer_id(submission_answer_id).await?;
        Ok(items.into_iter()
            .filter(|i| i.answer_text.is_some())
            .collect())
    }

    /// Update is_correct flag on a specific answer item
    pub async fn update_answer_item_correctness(
        &self,
        item_id: Uuid,
        is_correct: bool,
    ) -> AppResult<()> {
        let mut item: submission_answer_items::ActiveModel =
            submission_answer_items::Entity::find_by_id(item_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Answer item not found".to_string()))?
                .into();

        item.is_correct = Set(is_correct);

        item.update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update answer item: {}", e)))?;

        Ok(())
    }

    // ===== ITEM ANALYSIS BATCH QUERY =====

    /// Batch query for item analysis — fetches all per-student per-question answer details
    /// for an assessment. Returns data needed to compute difficulty/discrimination indices.
    pub async fn get_all_answer_details_for_assessment(
        &self,
        assessment_id: Uuid,
    ) -> AppResult<Vec<AnswerDetail>> {
        let rows = self
            .db
            .query_all(sea_orm::Statement::from_sql_and_values(
                sea_orm::DbBackend::Sqlite,
                r#"
                SELECT
                    s.user_id as student_id,
                    s.total_points as submission_total_points,
                    sa.question_id,
                    sa.points as answer_points,
                    sai.choice_id,
                    sai.is_correct as item_is_correct
                FROM assessment_submissions s
                JOIN submission_answers sa ON sa.submission_id = s.id
                LEFT JOIN submission_answer_items sai ON sai.submission_answer_id = sa.id
                WHERE s.assessment_id = $1
                  AND s.submitted_at IS NOT NULL
                  AND s.deleted_at IS NULL
                ORDER BY s.total_points DESC, sa.question_id
                "#,
                [assessment_id.into()],
            ))
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!(
                    "Failed to query answer details: {}",
                    e
                ))
            })?;

        let mut details = Vec::new();
        for row in rows {
            let student_id: String = row
                .try_get("", "student_id")
                .unwrap_or_default();
            let submission_total_points: f64 = row
                .try_get("", "submission_total_points")
                .unwrap_or(0.0);
            let question_id: String = row
                .try_get("", "question_id")
                .unwrap_or_default();
            let answer_points: f64 = row
                .try_get("", "answer_points")
                .unwrap_or(0.0);
            let choice_id: Option<String> = row
                .try_get("", "choice_id")
                .ok();
            let item_is_correct: bool = row
                .try_get("", "item_is_correct")
                .unwrap_or(false);

            details.push(AnswerDetail {
                student_id: Uuid::parse_str(&student_id).unwrap_or_default(),
                submission_total_points,
                question_id: Uuid::parse_str(&question_id).unwrap_or_default(),
                answer_points,
                choice_id: choice_id.and_then(|s| Uuid::parse_str(&s).ok()),
                item_is_correct,
            });
        }

        Ok(details)
    }

    pub async fn soft_delete_by_assessment(&self, assessment_id: Uuid) -> AppResult<()> {
        let now = Utc::now().naive_utc();
        let assessment_id_str = assessment_id.to_string();
        let now_str = now.to_string();

        let query = format!(
            "UPDATE assessment_submissions SET deleted_at = '{}', updated_at = '{}' WHERE assessment_id = '{}' AND deleted_at IS NULL",
            now_str, now_str, assessment_id_str
        );

        let _result = self.db.execute(sea_orm::Statement::from_string(
            sea_orm::DbBackend::Sqlite,
            query,
        ))
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to delete submissions: {}", e)))?;

        Ok(())
    }
}
