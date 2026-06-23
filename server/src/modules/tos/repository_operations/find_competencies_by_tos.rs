use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::tos_competencies;

pub async fn find_competencies_by_tos(
    db: &DatabaseConnection,
    tos_id: Uuid,
) -> AppResult<Vec<tos_competencies::Model>> {
    tos_competencies::Entity::find()
        .filter(tos_competencies::Column::TosId.eq(tos_id))
        .filter(tos_competencies::Column::DeletedAt.is_null())
        .order_by_asc(tos_competencies::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
