use sea_orm::*;
use uuid::Uuid;

use ::entity::learning_materials;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_materials_paginated(
    db: &DatabaseConnection,
    material_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = learning_materials::Entity::find()
        .filter(learning_materials::Column::Id.is_in(material_ids));
    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "class_id": r.class_id.to_string(),
            "title": r.title,
            "description": r.description,
            "content_text": r.content_text,
            "order_index": r.order_index,
            "created_at": r.created_at.to_string(),
            "updated_at": r.updated_at.to_string(),
        })
    })
    .await
}
