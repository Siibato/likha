use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::learning_materials;

pub async fn get_materials_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = learning_materials::Entity::find()
        .filter(learning_materials::Column::ClassId.is_in(class_ids));
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
