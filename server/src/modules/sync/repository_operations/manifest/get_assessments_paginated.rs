use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::assessments;

pub async fn get_assessments_paginated(
    db: &DatabaseConnection,
    assessment_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = assessments::Entity::find().filter(assessments::Column::Id.is_in(assessment_ids));
    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "class_id": r.class_id.to_string(),
            "title": r.title,
            "description": r.description,
            "time_limit_minutes": r.time_limit_minutes,
            "open_at": r.open_at.to_string(),
            "close_at": r.close_at.to_string(),
            "show_results_immediately": r.show_results_immediately,
            "is_published": r.is_published,
            "results_released": r.results_released,
            "order_index": r.order_index,
            "total_points": r.total_points,
            "term_number": r.term_number,
            "component": r.component,
            "tos_id": r.tos_id.map(|u| u.to_string()),
            "created_at": r.created_at.to_string(),
            "updated_at": r.updated_at.to_string(),
            "deleted_at": r.deleted_at.map(|d| d.to_string()),
        })
    })
    .await
}
