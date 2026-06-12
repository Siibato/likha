use sea_orm::*;
use uuid::Uuid;

use ::entity::assignments;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_assignments_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = assignments::Entity::find()
        .filter(assignments::Column::ClassId.is_in(class_ids));
    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "class_id": r.class_id.to_string(),
            "title": r.title,
            "instructions": r.instructions,
            "total_points": r.total_points,
            "allows_text_submission": r.allows_text_submission,
            "allows_file_submission": r.allows_file_submission,
            "allowed_file_types": r.allowed_file_types,
            "max_file_size_mb": r.max_file_size_mb,
            "due_at": r.due_at.to_string(),
            "is_published": r.is_published,
            "order_index": r.order_index,
            "grading_period_number": r.grading_period_number,
            "component": r.component,
            "created_at": r.created_at.to_string(),
            "updated_at": r.updated_at.to_string(),
            "deleted_at": r.deleted_at.map(|d| d.to_string()),
        })
    })
    .await
}
