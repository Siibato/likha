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
    let id = Uuid::new_v4();

    let sql = r#"
        INSERT INTO attendance_records (id, student_id, class_id, school_year, month, school_days, days_present, created_at, updated_at, deleted_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
        ON CONFLICT(student_id, class_id, school_year, month) DO UPDATE SET
            school_days = excluded.school_days,
            days_present = excluded.days_present,
            updated_at = excluded.updated_at,
            deleted_at = NULL
    "#;

    let stmt = Statement::from_sql_and_values(
        DbBackend::Sqlite,
        sql,
        vec![
            id.into(),
            student_id.into(),
            class_id.into(),
            school_year.clone().into(),
            month.clone().into(),
            school_days.into(),
            days_present.into(),
            now.into(),
            now.into(),
        ],
    );

    db.execute(stmt)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to upsert attendance: {}", e)))?;

    attendance_records::Entity::find()
        .filter(attendance_records::Column::StudentId.eq(student_id))
        .filter(attendance_records::Column::ClassId.eq(class_id))
        .filter(attendance_records::Column::SchoolYear.eq(&school_year))
        .filter(attendance_records::Column::Month.eq(&month))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::InternalServerError("Attendance record not found after upsert".to_string()))
}
