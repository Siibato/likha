use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::student_school_history;
use crate::utils::{AppError, AppResult};

pub async fn update_school_history(
    db: &DatabaseConnection,
    id: Uuid,
    school_name: Option<String>,
    school_id: Option<Option<String>>,
    grade_level: Option<String>,
    school_year: Option<String>,
    section: Option<Option<String>>,
    date_from: Option<Option<chrono::NaiveDate>>,
    date_to: Option<Option<chrono::NaiveDate>>,
    record_type: Option<String>,
) -> AppResult<student_school_history::Model> {
    let existing = student_school_history::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("School history not found".to_string()))?;

    let mut am: student_school_history::ActiveModel = existing.into();
    let now = Utc::now().naive_utc();

    if let Some(v) = school_name {
        am.school_name = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = school_id {
        am.school_id = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = grade_level {
        am.grade_level = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = school_year {
        am.school_year = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = section {
        am.section = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = date_from {
        am.date_from = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = date_to {
        am.date_to = sea_orm::ActiveValue::Set(v);
    }
    if let Some(v) = record_type {
        am.record_type = sea_orm::ActiveValue::Set(v);
    }
    am.updated_at = sea_orm::ActiveValue::Set(now);

    am.update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update school history: {}", e)))
}
