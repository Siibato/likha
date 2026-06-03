use sea_orm::*;
use uuid::Uuid;

use ::entity::assignment_submissions;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_student_assignment_submissions_for_assignments(
    db: &DatabaseConnection,
    user_id: Uuid,
    assignment_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::StudentId.eq(user_id))
        .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids));
    helpers::paginate_query(db, query, limit, |r| {
        serde_json::json!({
            "id": r.id.to_string(),
            "assignment_id": r.assignment_id.to_string(),
            "student_id": r.student_id.to_string(),
            "status": r.status,
            "text_content": r.text_content,
            "submitted_at": r.submitted_at.map(|d| d.to_string()),
            "points": r.points,
            "feedback": r.feedback,
            "graded_at": r.graded_at.map(|d| d.to_string()),
            "graded_by": r.graded_by.map(|id| id.to_string()),
            "created_at": r.created_at.to_string(),
            "updated_at": r.updated_at.to_string(),
            "deleted_at": r.deleted_at.map(|d| d.to_string()),
        })
    })
    .await
}
