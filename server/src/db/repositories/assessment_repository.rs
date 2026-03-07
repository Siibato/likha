use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{
    assessment_questions, assessments, enumeration_item_answers, enumeration_items,
    question_choices, question_correct_answers,
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
        client_id: Option<Uuid>,
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
            is_published: Set(false),
            total_points: Set(0),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
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
            .order_by_desc(assessments::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_published_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assessments::Model>> {
        assessments::Entity::find()
            .filter(assessments::Column::ClassId.eq(class_id))
            .filter(assessments::Column::IsPublished.eq(true))
            .order_by_desc(assessments::Column::CreatedAt)
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

    pub async fn delete_assessment(&self, id: Uuid) -> AppResult<()> {
        assessments::Entity::delete_by_id(id)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete assessment: {}", e)))?;
        Ok(())
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
    ) -> AppResult<question_correct_answers::Model> {
        let answer = question_correct_answers::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(question_id),
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
    ) -> AppResult<Vec<question_correct_answers::Model>> {
        question_correct_answers::Entity::find()
            .filter(question_correct_answers::Column::QuestionId.eq(question_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn delete_correct_answers_by_question_id(&self, question_id: Uuid) -> AppResult<()> {
        question_correct_answers::Entity::delete_many()
            .filter(question_correct_answers::Column::QuestionId.eq(question_id))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete correct answers: {}", e)))?;
        Ok(())
    }

    // ===== ENUMERATION ITEMS =====

    pub async fn add_enumeration_item(
        &self,
        question_id: Uuid,
        order_index: i32,
    ) -> AppResult<enumeration_items::Model> {
        let item = enumeration_items::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(question_id),
            order_index: Set(order_index),
        };

        item.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add enumeration item: {}", e)))
    }

    pub async fn find_enumeration_items_by_question_id(
        &self,
        question_id: Uuid,
    ) -> AppResult<Vec<enumeration_items::Model>> {
        enumeration_items::Entity::find()
            .filter(enumeration_items::Column::QuestionId.eq(question_id))
            .order_by_asc(enumeration_items::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn delete_enumeration_items_by_question_id(&self, question_id: Uuid) -> AppResult<()> {
        enumeration_items::Entity::delete_many()
            .filter(enumeration_items::Column::QuestionId.eq(question_id))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete enumeration items: {}", e)))?;
        Ok(())
    }

    pub async fn add_enumeration_item_answer(
        &self,
        enumeration_item_id: Uuid,
        answer_text: String,
    ) -> AppResult<enumeration_item_answers::Model> {
        let answer = enumeration_item_answers::ActiveModel {
            id: Set(Uuid::new_v4()),
            enumeration_item_id: Set(enumeration_item_id),
            answer_text: Set(answer_text.trim().to_lowercase()),
        };

        answer
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add enumeration item answer: {}", e)))
    }

    pub async fn find_enumeration_item_answers(
        &self,
        enumeration_item_id: Uuid,
    ) -> AppResult<Vec<enumeration_item_answers::Model>> {
        enumeration_item_answers::Entity::find()
            .filter(enumeration_item_answers::Column::EnumerationItemId.eq(enumeration_item_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
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
}
