use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::learning_materials;
use crate::utils::{AppError, AppResult};

pub async fn get_materials_since(
    db: &DatabaseConnection,
    material_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let records = learning_materials::Entity::find()
        .filter(learning_materials::Column::Id.is_in(material_ids))
        .filter(learning_materials::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = records
        .into_iter()
        .map(|r| {
            serde_json::json!({
                "id": r.id.to_string(),
                "class_id": r.class_id.to_string(),
                "title": r.title,
                "description": r.description,
                "content_text": r.content_text,
                "order_index": r.order_index,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .collect();

    Ok(records)
}
