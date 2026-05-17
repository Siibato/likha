use sea_orm::*;
use uuid::Uuid;

use ::entity::{assignment_submissions, users};
use crate::utils::{AppError, AppResult};

pub async fn find_submissions_by_assignment(
    db: &DatabaseConnection,
    assignment_id: Uuid,
) -> AppResult<Vec<(assignment_submissions::Model, Option<users::Model>)>> {
    assignment_submissions::Entity::find()
        .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
        .find_also_related(users::Entity)
        .order_by_asc(assignment_submissions::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
