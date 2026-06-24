use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessments;

pub async fn get_max_order_index(db: &DatabaseConnection, class_id: Uuid) -> AppResult<i32> {
    let result = assessments::Entity::find()
        .select_only()
        .column_as(assessments::Column::OrderIndex.max(), "max_order")
        .filter(assessments::Column::ClassId.eq(class_id))
        .filter(assessments::Column::DeletedAt.is_null())
        .into_tuple::<Option<i32>>()
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(result.flatten().unwrap_or(-1))
}
