use sea_orm::*;
use uuid::Uuid;

use ::entity::assessment_submissions;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_all_assessment_submissions_for_assessments(
    db: &DatabaseConnection,
    assessment_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = assessment_submissions::Entity::find()
        .filter(assessment_submissions::Column::AssessmentId.is_in(assessment_ids));
    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "assessment_id": r.assessment_id.to_string(),
            "user_id": r.user_id.to_string(),
            "started_at": r.started_at.to_string(),
            "submitted_at": r.submitted_at.map(|d| d.to_string()),
            "total_points": r.total_points,
            "created_at": r.created_at.to_string(),
            "updated_at": r.updated_at.to_string(),
            "deleted_at": r.deleted_at.map(|d| d.to_string()),
        })
    })
    .await
}
