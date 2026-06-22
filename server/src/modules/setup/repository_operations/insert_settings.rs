use chrono::Utc;
use sea_orm::*;

use ::entity::school_details;
use crate::utils::AppResult;

pub async fn insert_settings(db: &DatabaseConnection, default_code: String) -> AppResult<school_details::Model> {
    let model = school_details::ActiveModel {
        id: Set(1),
        school_code: Set(default_code.to_uppercase()),
        school_name: Set(None),
        school_region: Set(None),
        school_division: Set(None),
        school_year: Set(None),
        school_district: Set(None),
        school_head_name: Set(None),
        school_head_position: Set(None),
        updated_at: Set(Utc::now().naive_utc()),
    };
    model
        .insert(db)
        .await
        .map_err(|e| crate::utils::error::AppError::InternalServerError(format!("Database error: {}", e)))
}
