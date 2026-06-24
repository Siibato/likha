use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignment_submissions;
use std::collections::HashMap;

pub async fn find_student_submissions_for_assignments(
    db: &DatabaseConnection,
    assignment_ids: &[Uuid],
    student_id: Uuid,
) -> AppResult<HashMap<Uuid, assignment_submissions::Model>> {
    if assignment_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let submissions = assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids.iter().copied()))
        .filter(assignment_submissions::Column::StudentId.eq(student_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(submissions
        .into_iter()
        .map(|s| (s.assignment_id, s))
        .collect())
}
