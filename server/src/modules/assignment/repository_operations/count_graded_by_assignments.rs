use sea_orm::*;
use uuid::Uuid;

use ::entity::assignment_submissions;
use crate::utils::{AppError, AppResult};
use std::collections::HashMap;

pub async fn count_graded_by_assignments(
    db: &DatabaseConnection,
    assignment_ids: &[Uuid],
) -> AppResult<HashMap<Uuid, usize>> {
    if assignment_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let rows: Vec<(Uuid, i64)> = assignment_submissions::Entity::find()
        .select_only()
        .column(assignment_submissions::Column::AssignmentId)
        .column_as(assignment_submissions::Column::Id.count(), "count")
        .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids.iter().copied()))
        .filter(assignment_submissions::Column::Status.eq("graded"))
        .group_by(assignment_submissions::Column::AssignmentId)
        .into_tuple()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(rows.into_iter().map(|(id, count)| (id, count as usize)).collect())
}
