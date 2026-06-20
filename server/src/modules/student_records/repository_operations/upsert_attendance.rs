use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::attendance_records;
use crate::utils::{AppError, AppResult};

pub async fn upsert_attendance(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Uuid,
    school_year: String,
    month: String,
    school_days: i32,
    days_present: i32,
) -> AppResult<attendance_records::Model> {
    let now = Utc::now().naive_utc();

    let existing = attendance_records::Entity::find()
        .filter(attendance_records::Column::StudentId.eq(student_id))
        .filter(attendance_records::Column::ClassId.eq(class_id))
        .filter(attendance_records::Column::SchoolYear.eq(&school_year))
        .filter(attendance_records::Column::Month.eq(&month))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(model) = existing {
        let mut am: attendance_records::ActiveModel = model.into();
        am.school_days = sea_orm::ActiveValue::Set(school_days);
        am.days_present = sea_orm::ActiveValue::Set(days_present);
        am.updated_at = sea_orm::ActiveValue::Set(now);
        am.update(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update attendance: {}", e)))
    } else {
        let am = attendance_records::ActiveModel {
            id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
            student_id: sea_orm::ActiveValue::Set(student_id),
            class_id: sea_orm::ActiveValue::Set(class_id),
            school_year: sea_orm::ActiveValue::Set(school_year),
            month: sea_orm::ActiveValue::Set(month),
            school_days: sea_orm::ActiveValue::Set(school_days),
            days_present: sea_orm::ActiveValue::Set(days_present),
            created_at: sea_orm::ActiveValue::Set(now),
            updated_at: sea_orm::ActiveValue::Set(now),
            deleted_at: sea_orm::ActiveValue::Set(None),
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to insert attendance: {}", e)))
    }
}
