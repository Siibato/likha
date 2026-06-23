use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learning_materials;

pub async fn get_max_order_index(db: &DatabaseConnection, class_id: Uuid) -> AppResult<i32> {
    let result = learning_materials::Entity::find()
        .filter(learning_materials::Column::ClassId.eq(class_id))
        .order_by_desc(learning_materials::Column::OrderIndex)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(result.map(|m| m.order_index).unwrap_or(-1))
}
