use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::{AppError, AppResult};

pub async fn get_max_order_index(db: &DatabaseConnection, class_id: Uuid) -> AppResult<i32> {
    let result = assignments::Entity::find()
        .select_only()
        .column_as(assignments::Column::OrderIndex.max(), "max_order")
        .filter(assignments::Column::ClassId.eq(class_id))
        .filter(assignments::Column::DeletedAt.is_null())
        .into_tuple::<Option<i32>>()
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(result.flatten().unwrap_or(-1))
}
