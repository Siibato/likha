use sea_orm::*;
use uuid::Uuid;

use ::entity::grade_items;
use crate::utils::{AppError, AppResult};

pub async fn get_grade_item_ids_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<Uuid>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = grade_items::Entity::find()
        .filter(grade_items::Column::ClassId.is_in(class_ids))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(|r| r.id).collect())
}
