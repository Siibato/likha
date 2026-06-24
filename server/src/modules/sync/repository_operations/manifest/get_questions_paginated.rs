use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::assessment_questions;

pub async fn get_questions_paginated(
    db: &DatabaseConnection,
    question_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = assessment_questions::Entity::find()
        .filter(assessment_questions::Column::Id.is_in(question_ids));
    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "assessment_id": r.assessment_id.to_string(),
            "question_type": r.question_type,
            "question_text": r.question_text,
            "points": r.points,
            "order_index": r.order_index,
            "is_multi_select": r.is_multi_select,
            "updated_at": r.updated_at.to_string(),
            "deleted_at": r.deleted_at.map(|d| d.to_string()),
        })
    })
    .await
}
