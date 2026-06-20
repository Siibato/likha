use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::core_values_records;
use crate::utils::{AppError, AppResult};

pub async fn upsert_core_values(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Uuid,
    school_year: String,
    term_number: i32,
    core_value_id: i32,
    marking: String,
) -> AppResult<core_values_records::Model> {
    let now = Utc::now().naive_utc();

    let existing = core_values_records::Entity::find()
        .filter(core_values_records::Column::StudentId.eq(student_id))
        .filter(core_values_records::Column::ClassId.eq(class_id))
        .filter(core_values_records::Column::SchoolYear.eq(&school_year))
        .filter(core_values_records::Column::TermNumber.eq(term_number))
        .filter(core_values_records::Column::CoreValueId.eq(core_value_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(model) = existing {
        let mut am: core_values_records::ActiveModel = model.into();
        am.marking = sea_orm::ActiveValue::Set(marking);
        am.updated_at = sea_orm::ActiveValue::Set(now);
        am.update(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update core values: {}", e)))
    } else {
        let am = core_values_records::ActiveModel {
            id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
            student_id: sea_orm::ActiveValue::Set(student_id),
            class_id: sea_orm::ActiveValue::Set(class_id),
            school_year: sea_orm::ActiveValue::Set(school_year),
            term_number: sea_orm::ActiveValue::Set(term_number),
            core_value_id: sea_orm::ActiveValue::Set(core_value_id),
            marking: sea_orm::ActiveValue::Set(marking),
            created_at: sea_orm::ActiveValue::Set(now),
            updated_at: sea_orm::ActiveValue::Set(now),
            deleted_at: sea_orm::ActiveValue::Set(None),
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to insert core values: {}", e)))
    }
}
