use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::previous_school_term_grades;

pub async fn get_term_grades_for_subject(
    db: &DatabaseConnection,
    subject_id: Uuid,
) -> AppResult<Vec<Option<i32>>> {
    let grades = previous_school_term_grades::Entity::find()
        .filter(previous_school_term_grades::Column::SubjectId.eq(subject_id))
        .filter(previous_school_term_grades::Column::DeletedAt.is_null())
        .order_by_asc(previous_school_term_grades::Column::TermNumber)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(grades.into_iter().map(|g| g.grade).collect())
}
