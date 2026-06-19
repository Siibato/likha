use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;

use ::entity::school_settings;
use crate::utils::{AppError, AppResult};

pub async fn get_school_settings_since(
    db: &DatabaseConnection,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let record = school_settings::Entity::find()
        .filter(school_settings::Column::UpdatedAt.gt(since))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let records: Vec<Value> = match record {
        Some(r) => vec![serde_json::json!({
            "id": r.id.to_string(),
            "school_code": r.school_code,
            "school_name": r.school_name,
            "school_region": r.school_region,
            "school_division": r.school_division,
            "school_year": r.school_year,
            "school_district": r.school_district,
            "school_head_name": r.school_head_name,
            "school_head_position": r.school_head_position,
            "updated_at": r.updated_at.to_string(),
        })],
        None => vec![],
    };

    Ok(records)
}
