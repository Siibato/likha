use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::school_settings;
use crate::utils::AppResult;

pub async fn insert_settings(db: &DatabaseConnection, default_code: String) -> AppResult<school_settings::Model> {
    let model = school_settings::ActiveModel {
        id: Set(1),
        school_code: Set(default_code.to_uppercase()),
        school_name: Set(None),
        school_region: Set(None),
        school_division: Set(None),
        school_year: Set(None),
        updated_at: Set(Utc::now().naive_utc()),
    };
    model
        .insert(db)
        .await
        .map_err(|e| crate::utils::error::AppError::InternalServerError(format!("Database error: {}", e)))
}
