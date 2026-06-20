use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::student_school_history;
use crate::utils::{AppError, AppResult};

pub async fn create_school_history(
    db: &DatabaseConnection,
    student_id: Uuid,
    school_name: String,
    school_id: Option<String>,
    grade_level: String,
    school_year: String,
    section: Option<String>,
    date_from: Option<chrono::NaiveDate>,
    date_to: Option<chrono::NaiveDate>,
    record_type: String,
) -> AppResult<student_school_history::Model> {
    let now = Utc::now().naive_utc();

    let am = student_school_history::ActiveModel {
        id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
        student_id: sea_orm::ActiveValue::Set(student_id),
        school_name: sea_orm::ActiveValue::Set(school_name),
        school_id: sea_orm::ActiveValue::Set(school_id),
        grade_level: sea_orm::ActiveValue::Set(grade_level),
        school_year: sea_orm::ActiveValue::Set(school_year),
        section: sea_orm::ActiveValue::Set(section),
        date_from: sea_orm::ActiveValue::Set(date_from),
        date_to: sea_orm::ActiveValue::Set(date_to),
        record_type: sea_orm::ActiveValue::Set(record_type),
        created_at: sea_orm::ActiveValue::Set(now),
        updated_at: sea_orm::ActiveValue::Set(now),
        deleted_at: sea_orm::ActiveValue::Set(None),
    };
    am.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create school history: {}", e)))
}
