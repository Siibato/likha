use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignment_submissions;

pub async fn find_student_submission(
    db: &DatabaseConnection,
    assignment_id: Uuid,
    student_id: Uuid,
) -> AppResult<Option<assignment_submissions::Model>> {
    assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
        .filter(assignment_submissions::Column::StudentId.eq(student_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
