use sea_orm::*;
use uuid::Uuid;

use ::entity::grade_items;
use crate::utils::{AppError, AppResult};

pub async fn get_items(
    db: &DatabaseConnection,
    class_id: Uuid,
    term_number: i32,
) -> AppResult<Vec<grade_items::Model>> {
    grade_items::Entity::find()
        .filter(grade_items::Column::ClassId.eq(class_id))
        .filter(grade_items::Column::TermNumber.eq(term_number))
        .filter(grade_items::Column::DeletedAt.is_null())
        .order_by_asc(grade_items::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
