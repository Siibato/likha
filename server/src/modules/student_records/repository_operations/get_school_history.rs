use sea_orm::*;
use uuid::Uuid;

use ::entity::student_school_history;
use crate::utils::{AppError, AppResult};

pub async fn get_school_history(
    db: &DatabaseConnection,
    student_id: Uuid,
) -> AppResult<Vec<student_school_history::Model>> {
    student_school_history::Entity::find()
        .filter(student_school_history::Column::StudentId.eq(student_id))
        .order_by_asc(student_school_history::Column::SchoolYear)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
