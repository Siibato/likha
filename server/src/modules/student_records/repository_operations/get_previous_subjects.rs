use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::previous_school_subjects;

pub async fn get_previous_subjects(
    db: &DatabaseConnection,
    student_id: Uuid,
    school_history_id: Option<Uuid>,
) -> AppResult<Vec<previous_school_subjects::Model>> {
    let mut query = previous_school_subjects::Entity::find()
        .filter(previous_school_subjects::Column::StudentId.eq(student_id));

    if let Some(sid) = school_history_id {
        query = query.filter(previous_school_subjects::Column::SchoolHistoryId.eq(sid));
    }

    query
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
