use sea_orm::*;
use uuid::Uuid;

use super::helpers;
use super::PaginatedRecords;
use crate::utils::AppResult;
use ::entity::activity_logs;

pub async fn get_activity_logs_paginated(
    db: &DatabaseConnection,
    log_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if log_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }

    let query = activity_logs::Entity::find().filter(activity_logs::Column::Id.is_in(log_ids));

    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "user_id": r.user_id.to_string(),
            "action": r.action,
            "details": r.details,
            "created_at": r.created_at.to_string(),
        })
    })
    .await
}
