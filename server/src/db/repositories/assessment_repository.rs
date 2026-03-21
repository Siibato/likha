use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{
    answer_key_acceptable_answers, answer_keys, assessment_questions, assessments,
    question_choices,
};
use crate::utils::{AppError, AppResult};

pub struct AssessmentRepository {
    db: DatabaseConnection,
}

impl AssessmentRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_assessment(
        &self,
        class_id: Uuid,
        title: String,
        description: Option<String>,
        time_limit_minutes: i32,
        open_at: chrono::NaiveDateTime,
        close_at: chrono::NaiveDateTime,
        show_results_immediately: bool,
        order_index: i32,
        client_id: Option<Uuid>,
        is_published: bool,
    ) -> AppResult<assessments::Model> {
        let assessment = assessments::ActiveModel {
            id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
            class_id: Set(class_id),
            title: Set(title),
            description: Set(description),
            time_limit_minutes: Set(time_limit_minutes),
            open_at: Set(open_at),
            close_at: Set(close_at),
            show_results_immediately: Set(show_results_immediately),
            results_released: Set(false),
            is_published: Set(is_published),
            order_index: Set(order_index),
            total_points: Set(0),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
            quarter: Set(None),
            is_departmental_exam: Set(None),
            component: Set(None),
        };

        assessment
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create assessment: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<assessments::Model>> {
        assessments::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assessments::Model>> {
        assessments::Entity::find()
            .filter(assessments::Column::ClassId.eq(class_id))
            .filter(assessments::Column::DeletedAt.is_null())
            .order_by_asc(assessments::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_published_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assessments::Model>> {
        assessments::Entity::find()
            .filter(assessments::Column::ClassId.eq(class_id))
            .filter(assessments::Column::IsPublished.eq(true))
            .filter(assessments::Column::DeletedAt.is_null())
            .order_by_asc(assessments::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_assessment(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<String>,
        time_limit_minutes: Option<i32>,
        open_at: Option<chrono::NaiveDateTime>,
        close_at: Option<chrono::NaiveDateTime>,
        show_results_immediately: Option<bool>,
    ) -> AppResult<assessments::Model> {
        let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
            .into();

        if let Some(title) = title {
            assessment.title = Set(title);
        }
        if let Some(desc) = description {
            assessment.description = Set(Some(desc));
        }
        if let Some(time) = time_limit_minutes {
            assessment.time_limit_minutes = Set(time);
        }
        if let Some(open) = open_at {
            assessment.open_at = Set(open);
        }
        if let Some(close) = close_at {
            assessment.close_at = Set(close);
        }
        if let Some(show) = show_results_immediately {
            assessment.show_results_immediately = Set(show);
        }
        assessment.updated_at = Set(Utc::now().naive_utc());

        assessment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update assessment: {}", e)))
    }

    pub async fn publish_assessment(&self, id: Uuid) -> AppResult<assessments::Model> {
        let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
            .into();

        assessment.is_published = Set(true);
        assessment.updated_at = Set(Utc::now().naive_utc());

        assessment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to publish assessment: {}", e)))
    }

    pub async fn unpublish_assessment(&self, id: Uuid) -> AppResult<assessments::Model> {
        let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
            .into();

        assessment.is_published = Set(false);
        assessment.updated_at = Set(Utc::now().naive_utc());

        assessment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to unpublish assessment: {}", e)))
    }

    pub async fn release_results(&self, id: Uuid) -> AppResult<assessments::Model> {
        let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
            .into();

        assessment.results_released = Set(true);
        assessment.updated_at = Set(Utc::now().naive_utc());

        assessment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to release results: {}", e)))
    }

    pub async fn update_total_points(&self, assessment_id: Uuid) -> AppResult<()> {
        let questions = self.find_questions_by_assessment_id(assessment_id).await?;
        let total: i32 = questions.iter().map(|q| q.points).sum();

        let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(assessment_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
            .into();

        assessment.total_points = Set(total);
        assessment.updated_at = Set(Utc::now().naive_utc());

        assessment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update total points: {}", e)))?;

        Ok(())
    }

    // ===== QUESTIONS =====

    pub async fn add_question(
        &self,
        assessment_id: Uuid,
        question_type: String,
        question_text: String,
        points: i32,
        order_index: i32,
        is_multi_select: bool,
        client_id: Option<Uuid>,
    ) -> AppResult<assessment_questions::Model> {
        let question = assessment_questions::ActiveModel {
            id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
            assessment_id: Set(assessment_id),
            question_type: Set(question_type),
            question_text: Set(question_text),
            points: Set(points),
            order_index: Set(order_index),
            is_multi_select: Set(is_multi_select),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
        };

        question
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add question: {}", e)))
    }

    pub async fn find_question_by_id(&self, id: Uuid) -> AppResult<Option<assessment_questions::Model>> {
        assessment_questions::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_questions_by_assessment_id(
        &self,
        assessment_id: Uuid,
    ) -> AppResult<Vec<assessment_questions::Model>> {
        assessment_questions::Entity::find()
            .filter(assessment_questions::Column::AssessmentId.eq(assessment_id))
            .order_by_asc(assessment_questions::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_question(
        &self,
        id: Uuid,
        question_text: Option<String>,
        points: Option<i32>,
        order_index: Option<i32>,
        is_multi_select: Option<bool>,
    ) -> AppResult<assessment_questions::Model> {
        let mut question: assessment_questions::ActiveModel =
            assessment_questions::Entity::find_by_id(id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?
                .into();

        if let Some(text) = question_text {
            question.question_text = Set(text);
        }
        if let Some(pts) = points {
            question.points = Set(pts);
        }
        if let Some(idx) = order_index {
            question.order_index = Set(idx);
        }
        if let Some(ms) = is_multi_select {
            question.is_multi_select = Set(ms);
        }

        question
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update question: {}", e)))
    }

    pub async fn delete_question(&self, id: Uuid) -> AppResult<()> {
        assessment_questions::Entity::delete_by_id(id)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete question: {}", e)))?;
        Ok(())
    }

    // ===== CHOICES =====

    pub async fn add_choice(
        &self,
        question_id: Uuid,
        choice_text: String,
        is_correct: bool,
        order_index: i32,
    ) -> AppResult<question_choices::Model> {
        let choice = question_choices::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(question_id),
            choice_text: Set(choice_text),
            is_correct: Set(is_correct),
            order_index: Set(order_index),
        };

        choice
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add choice: {}", e)))
    }

    pub async fn find_choices_by_question_id(
        &self,
        question_id: Uuid,
    ) -> AppResult<Vec<question_choices::Model>> {
        question_choices::Entity::find()
            .filter(question_choices::Column::QuestionId.eq(question_id))
            .order_by_asc(question_choices::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn delete_choices_by_question_id(&self, question_id: Uuid) -> AppResult<()> {
        question_choices::Entity::delete_many()
            .filter(question_choices::Column::QuestionId.eq(question_id))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete choices: {}", e)))?;
        Ok(())
    }

    // ===== CORRECT ANSWERS =====

    pub async fn add_correct_answer(
        &self,
        question_id: Uuid,
        answer_text: String,
    ) -> AppResult<answer_key_acceptable_answers::Model> {
        // First, create or get the answer key for this question
        let answer_key = answer_keys::Entity::find()
            .filter(answer_keys::Column::QuestionId.eq(question_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let answer_key_id = if let Some(key) = answer_key {
            key.id
        } else {
            // Create new answer key if it doesn't exist
            let new_key = answer_keys::ActiveModel {
                id: Set(Uuid::new_v4()),
                question_id: Set(question_id),
            };
            let inserted = new_key
                .insert(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to create answer key: {}", e)))?;
            inserted.id
        };

        // Now add the acceptable answer
        let answer = answer_key_acceptable_answers::ActiveModel {
            id: Set(Uuid::new_v4()),
            answer_key_id: Set(answer_key_id),
            answer_text: Set(answer_text.trim().to_lowercase()),
        };

        answer
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add correct answer: {}", e)))
    }

    pub async fn find_correct_answers_by_question_id(
        &self,
        question_id: Uuid,
    ) -> AppResult<Vec<answer_key_acceptable_answers::Model>> {
        // Find the answer key for this question
        let answer_key = answer_keys::Entity::find()
            .filter(answer_keys::Column::QuestionId.eq(question_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(key) = answer_key {
            answer_key_acceptable_answers::Entity::find()
                .filter(answer_key_acceptable_answers::Column::AnswerKeyId.eq(key.id))
                .all(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
        } else {
            Ok(vec![])
        }
    }

    pub async fn delete_correct_answers_by_question_id(&self, question_id: Uuid) -> AppResult<()> {
        // Find and delete the answer key (which will cascade to acceptable answers)
        let answer_key = answer_keys::Entity::find()
            .filter(answer_keys::Column::QuestionId.eq(question_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(key) = answer_key {
            answer_keys::Entity::delete_by_id(key.id)
                .exec(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to delete answer key: {}", e)))?;
        }
        Ok(())
    }

    pub async fn find_all(&self) -> AppResult<Vec<assessments::Model>> {
        assessments::Entity::find()
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        let assessment = assessments::ActiveModel {
            id: Set(id),
            deleted_at: Set(Some(Utc::now().naive_utc())),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        assessments::Entity::update(assessment)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete assessment: {}", e)))?;

        Ok(())
    }

    pub async fn get_max_order_index(&self, class_id: Uuid) -> AppResult<i32> {
        let result = assessments::Entity::find()
            .select_only()
            .column_as(assessments::Column::OrderIndex.max(), "max_order")
            .filter(assessments::Column::ClassId.eq(class_id))
            .filter(assessments::Column::DeletedAt.is_null())
            .into_tuple::<Option<i32>>()
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(result.flatten().unwrap_or(-1))
    }

    pub async fn reorder_assessments(&self, _class_id: Uuid, assessment_ids: Vec<Uuid>) -> AppResult<()> {
        for (index, id) in assessment_ids.iter().enumerate() {
            let assessment = assessments::ActiveModel {
                id: Set(*id),
                order_index: Set(index as i32),
                updated_at: Set(Utc::now().naive_utc()),
                ..Default::default()
            };

            assessments::Entity::update(assessment)
                .exec(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to reorder assessment: {}", e)))?;
        }

        Ok(())
    }

    pub async fn reorder_questions(&self, _assessment_id: Uuid, question_ids: Vec<Uuid>) -> AppResult<()> {
        for (index, id) in question_ids.iter().enumerate() {
            let question = assessment_questions::ActiveModel {
                id: Set(*id),
                order_index: Set(index as i32),
                updated_at: Set(Utc::now().naive_utc()),
                ..Default::default()
            };
            assessment_questions::Entity::update(question)
                .exec(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to reorder question: {}", e)))?;
        }

        Ok(())
    }

    /// Fetches all enumeration items (answer_keys) for a question with their acceptable answers.
    pub async fn find_enumeration_items_for_question(&self, question_id: Uuid) -> AppResult<Vec<(answer_keys::Model, Vec<answer_key_acceptable_answers::Model>)>> {
        let keys = answer_keys::Entity::find()
            .filter(answer_keys::Column::QuestionId.eq(question_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to fetch answer keys: {}", e)))?;

        let mut result = Vec::new();
        for key in keys {
            let answers = answer_key_acceptable_answers::Entity::find()
                .filter(answer_key_acceptable_answers::Column::AnswerKeyId.eq(key.id))
                .all(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to fetch acceptable answers: {}", e)))?;
            result.push((key, answers));
        }
        Ok(result)
    }

    /// Creates one answer_key row + its acceptable answer rows for one enumeration slot.
    pub async fn add_enumeration_item(
        &self,
        question_id: Uuid,
        acceptable_answers: Vec<String>,
    ) -> AppResult<answer_keys::Model> {
        let new_key = answer_keys::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(question_id),
        };
        let inserted = new_key
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create answer key: {}", e)))?;

        for text in acceptable_answers {
            let answer = answer_key_acceptable_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                answer_key_id: Set(inserted.id),
                answer_text: Set(text.trim().to_lowercase()),
            };
            answer
                .insert(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to add enumeration answer: {}", e)))?;
        }
        Ok(inserted)
    }

    /// Deletes ALL answer_key rows for a question (cascades to acceptable_answers).
    pub async fn delete_all_answer_keys_for_question(&self, question_id: Uuid) -> AppResult<()> {
        let keys = answer_keys::Entity::find()
            .filter(answer_keys::Column::QuestionId.eq(question_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        for key in keys {
            answer_keys::Entity::delete_by_id(key.id)
                .exec(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to delete answer key: {}", e)))?;
        }
        Ok(())
    }
}
