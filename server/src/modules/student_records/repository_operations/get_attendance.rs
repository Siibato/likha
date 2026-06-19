use sea_orm::*;
use uuid::Uuid;

use ::entity::attendance_records;
use crate::utils::{AppError, AppResult};

pub async fn get_attendance(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Option<Uuid>,
    school_year: Option<&str>,
) -> AppResult<Vec<attendance_records::Model>> {
    let mut query = attendance_records::Entity::find()
        .filter(attendance_records::Column::StudentId.eq(student_id));

    if let Some(cid) = class_id {
        query = query.filter(attendance_records::Column::ClassId.eq(cid));
    }
    if let Some(sy) = school_year {
        query = query.filter(attendance_records::Column::SchoolYear.eq(sy));
    }

    query
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
