use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::previous_school_attendance;

pub async fn get_previous_attendance(
    db: &DatabaseConnection,
    student_id: Uuid,
    school_history_id: Option<Uuid>,
) -> AppResult<Vec<previous_school_attendance::Model>> {
    let mut query = previous_school_attendance::Entity::find()
        .filter(previous_school_attendance::Column::StudentId.eq(student_id));

    if let Some(sid) = school_history_id {
        query = query.filter(previous_school_attendance::Column::SchoolHistoryId.eq(sid));
    }

    query
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
