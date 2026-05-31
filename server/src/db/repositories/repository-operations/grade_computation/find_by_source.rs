use sea_orm::*;

use ::entity::grade_items;
use crate::utils::{AppError, AppResult};

pub async fn find_by_source(
    db: &DatabaseConnection,
    source_type: &str,
    source_id: &str,
) -> AppResult<Option<grade_items::Model>> {
    grade_items::Entity::find()
        .filter(grade_items::Column::SourceType.eq(source_type))
        .filter(grade_items::Column::SourceId.eq(source_id))
        .filter(grade_items::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
