use sea_orm::*;
use uuid::Uuid;

use ::entity::assignment_submissions;
use crate::utils::{AppError, AppResult};

pub async fn count_graded_by_assignment(
    db: &DatabaseConnection,
    assignment_id: Uuid,
) -> AppResult<usize> {
    let count = assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
        .filter(assignment_submissions::Column::Status.eq("graded"))
        .count(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(count as usize)
}
