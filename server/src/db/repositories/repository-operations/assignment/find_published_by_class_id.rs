use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn find_published_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
) -> AppResult<Vec<assignments::Model>> {
    assignments::Entity::find()
        .filter(assignments::Column::ClassId.eq(class_id))
        .filter(assignments::Column::IsPublished.eq(true))
        .filter(assignments::Column::DeletedAt.is_null())
        .order_by_asc(assignments::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
