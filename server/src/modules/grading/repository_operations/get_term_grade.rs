use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::term_grades;

pub async fn get_term_grade(
    db: &DatabaseConnection,
    class_id: Uuid,
    student_id: Uuid,
    term_number: i32,
) -> AppResult<Option<term_grades::Model>> {
    term_grades::Entity::find()
        .filter(term_grades::Column::ClassId.eq(class_id))
        .filter(term_grades::Column::StudentId.eq(student_id))
        .filter(term_grades::Column::TermNumber.eq(term_number))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
