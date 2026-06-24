use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learner_details;

pub async fn get_learner_details(
    db: &DatabaseConnection,
    user_id: Uuid,
) -> AppResult<Option<learner_details::Model>> {
    learner_details::Entity::find()
        .filter(learner_details::Column::UserId.eq(user_id))
        .filter(learner_details::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
