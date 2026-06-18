use chrono::Utc;
use sea_orm::*;

use ::entity::school_settings;
use crate::utils::{AppError, AppResult};

pub async fn update_settings(
    db: &DatabaseConnection,
    school_code: Option<String>,
    school_name: Option<Option<String>>,
    school_region: Option<Option<String>>,
    school_division: Option<Option<String>>,
    school_year: Option<Option<String>>,
    school_district: Option<Option<String>>,
) -> AppResult<school_settings::Model> {
    let row = super::get_settings(db).await?;
    let mut active: school_settings::ActiveModel = row.into();

    if let Some(code) = school_code {
        active.school_code = Set(code);
    }
    if let Some(name) = school_name {
        active.school_name = Set(name);
    }
    if let Some(region) = school_region {
        active.school_region = Set(region);
    }
    if let Some(division) = school_division {
        active.school_division = Set(division);
    }
    if let Some(year) = school_year {
        active.school_year = Set(year);
    }
    if let Some(district) = school_district {
        active.school_district = Set(district);
    }
    active.updated_at = Set(Utc::now().naive_utc());

    active
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
