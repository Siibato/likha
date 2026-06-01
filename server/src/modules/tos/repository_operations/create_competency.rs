use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::tos_competencies;
use crate::utils::{AppError, AppResult};

pub async fn create_competency(
    db: &DatabaseConnection,
    id: Uuid,
    tos_id: Uuid,
    competency_code: Option<&str>,
    competency_text: &str,
    time_units_taught: i32,
    order_index: i32,
    easy_count: Option<i32>,
    medium_count: Option<i32>,
    hard_count: Option<i32>,
    remembering_count: Option<i32>,
    understanding_count: Option<i32>,
    applying_count: Option<i32>,
    analyzing_count: Option<i32>,
    evaluating_count: Option<i32>,
    creating_count: Option<i32>,
) -> AppResult<tos_competencies::Model> {
    let now = Utc::now().naive_utc();
    let comp = tos_competencies::ActiveModel {
        id: Set(id),
        tos_id: Set(tos_id),
        competency_code: Set(competency_code.map(|s| s.to_string())),
        competency_text: Set(competency_text.to_string()),
        time_units_taught: Set(time_units_taught),
        order_index: Set(order_index),
        easy_count: Set(easy_count),
        medium_count: Set(medium_count),
        hard_count: Set(hard_count),
        remembering_count: Set(remembering_count),
        understanding_count: Set(understanding_count),
        applying_count: Set(applying_count),
        analyzing_count: Set(analyzing_count),
        evaluating_count: Set(evaluating_count),
        creating_count: Set(creating_count),
        created_at: Set(now),
        updated_at: Set(now),
        deleted_at: Set(None),
    };

    comp.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create competency: {}", e)))
}
