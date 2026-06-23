use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learning_materials;

pub async fn find_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
) -> AppResult<Vec<learning_materials::Model>> {
    learning_materials::Entity::find()
        .filter(learning_materials::Column::ClassId.eq(class_id))
        .filter(learning_materials::Column::DeletedAt.is_null())
        .order_by_asc(learning_materials::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
