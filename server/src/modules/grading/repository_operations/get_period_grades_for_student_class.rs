use sea_orm::*;
use uuid::Uuid;

use ::entity::period_grades;
use crate::utils::{AppError, AppResult};

pub async fn get_period_grades_for_student_class(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Uuid,
) -> AppResult<Vec<period_grades::Model>> {
    period_grades::Entity::find()
        .filter(period_grades::Column::StudentId.eq(student_id))
        .filter(period_grades::Column::ClassId.eq(class_id))
        .filter(period_grades::Column::DeletedAt.is_null())
        .order_by_asc(period_grades::Column::GradingPeriodNumber)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
