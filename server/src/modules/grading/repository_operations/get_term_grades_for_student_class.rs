use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::term_grades;

pub async fn get_term_grades_for_student_class(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Uuid,
) -> AppResult<Vec<term_grades::Model>> {
    term_grades::Entity::find()
        .filter(term_grades::Column::StudentId.eq(student_id))
        .filter(term_grades::Column::ClassId.eq(class_id))
        .filter(term_grades::Column::DeletedAt.is_null())
        .order_by_asc(term_grades::Column::TermNumber)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
