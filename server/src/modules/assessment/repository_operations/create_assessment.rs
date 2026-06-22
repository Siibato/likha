use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assessments;
use crate::utils::{AppError, AppResult};

pub async fn create_assessment(
    db: &DatabaseConnection,
    class_id: Uuid,
    title: String,
    description: Option<String>,
    time_limit_minutes: i32,
    open_at: chrono::NaiveDateTime,
    close_at: chrono::NaiveDateTime,
    show_results_immediately: bool,
    order_index: i32,
    client_id: Option<Uuid>,
    is_published: bool,
    term_number: Option<i32>,
    component: Option<String>,
    tos_id: Option<String>,
) -> AppResult<assessments::Model> {
    let tos_id = match tos_id {
        Some(s) if !s.is_empty() => Some(
            Uuid::parse_str(&s)
                .map_err(|e| AppError::BadRequest(format!("Invalid tos_id UUID: {}", e)))?,
        ),
        _ => None,
    };
    let assessment = assessments::ActiveModel {
        id: Set(client_id.unwrap_or_else(Uuid::new_v4)),
        class_id: Set(class_id),
        title: Set(title),
        description: Set(description),
        time_limit_minutes: Set(time_limit_minutes),
        open_at: Set(open_at),
        close_at: Set(close_at),
        show_results_immediately: Set(show_results_immediately),
        results_released: Set(false),
        is_published: Set(is_published),
        order_index: Set(order_index),
        total_points: Set(0),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
        term_number: Set(term_number),
        component: Set(component),
        tos_id: Set(tos_id),
    };

    assessment
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create assessment: {}", e)))
}
