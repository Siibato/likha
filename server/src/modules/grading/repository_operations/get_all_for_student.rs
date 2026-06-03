use sea_orm::*;
use uuid::Uuid;

use ::entity::period_grades;
use crate::utils::{AppError, AppResult};

pub async fn get_all_for_student(
    db: &DatabaseConnection,
    class_id: Uuid,
    student_id: Uuid,
) -> AppResult<Vec<period_grades::Model>> {
    period_grades::Entity::find()
        .filter(period_grades::Column::ClassId.eq(class_id))
        .filter(period_grades::Column::StudentId.eq(student_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
