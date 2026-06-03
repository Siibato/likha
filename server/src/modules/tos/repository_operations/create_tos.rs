use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::table_of_specifications;
use crate::utils::{AppError, AppResult};

pub async fn create_tos(
    db: &DatabaseConnection,
    id: Uuid,
    class_id: Uuid,
    grading_period_number: i32,
    title: &str,
    classification_mode: &str,
    total_items: i32,
    time_unit: &str,
    easy_percentage: f64,
    medium_percentage: f64,
    hard_percentage: f64,
    remembering_percentage: f64,
    understanding_percentage: f64,
    applying_percentage: f64,
    analyzing_percentage: f64,
    evaluating_percentage: f64,
    creating_percentage: f64,
) -> AppResult<table_of_specifications::Model> {
    let now = Utc::now().naive_utc();
    let tos = table_of_specifications::ActiveModel {
        id: Set(id),
        class_id: Set(class_id),
        grading_period_number: Set(grading_period_number),
        title: Set(title.to_string()),
        classification_mode: Set(classification_mode.to_string()),
        total_items: Set(total_items),
        time_unit: Set(time_unit.to_string()),
        easy_percentage: Set(easy_percentage),
        medium_percentage: Set(medium_percentage),
        hard_percentage: Set(hard_percentage),
        remembering_percentage: Set(remembering_percentage),
        understanding_percentage: Set(understanding_percentage),
        applying_percentage: Set(applying_percentage),
        analyzing_percentage: Set(analyzing_percentage),
        evaluating_percentage: Set(evaluating_percentage),
        creating_percentage: Set(creating_percentage),
        created_at: Set(now),
        updated_at: Set(now),
        deleted_at: Set(None),
    };

    tos.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create TOS: {}", e)))
}
