use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn find_published_by_class_ids(
    db: &DatabaseConnection,
    class_ids: &[Uuid],
) -> AppResult<Vec<assignments::Model>> {
    if class_ids.is_empty() {
        return Ok(vec![]);
    }

    assignments::Entity::find()
        .filter(assignments::Column::ClassId.is_in(class_ids.iter().copied()))
        .filter(assignments::Column::IsPublished.eq(true))
        .filter(assignments::Column::DeletedAt.is_null())
        .order_by_asc(assignments::Column::ClassId)
        .order_by_asc(assignments::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
