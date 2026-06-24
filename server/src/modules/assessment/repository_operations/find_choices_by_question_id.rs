use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::question_choices;

pub async fn find_choices_by_question_id(
    db: &DatabaseConnection,
    question_id: Uuid,
) -> AppResult<Vec<question_choices::Model>> {
    question_choices::Entity::find()
        .filter(question_choices::Column::QuestionId.eq(question_id))
        .order_by_asc(question_choices::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
