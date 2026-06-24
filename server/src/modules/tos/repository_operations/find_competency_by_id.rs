use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::tos_competencies;

pub async fn find_competency_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<tos_competencies::Model>> {
    tos_competencies::Entity::find_by_id(id)
        .filter(tos_competencies::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
