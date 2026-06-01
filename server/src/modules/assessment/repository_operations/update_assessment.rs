use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::assessments;
use crate::utils::{AppError, AppResult};

pub async fn update_assessment(
    db: &DatabaseConnection,
    id: Uuid,
    title: Option<String>,
    description: Option<String>,
    time_limit_minutes: Option<i32>,
    open_at: Option<chrono::NaiveDateTime>,
    close_at: Option<chrono::NaiveDateTime>,
    show_results_immediately: Option<bool>,
    grading_period_number: Option<Option<i32>>,
    component: Option<Option<String>>,
    tos_id: Option<Option<String>>,
) -> AppResult<assessments::Model> {
    let mut assessment: assessments::ActiveModel = assessments::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?
        .into();

    if let Some(title) = title {
        assessment.title = Set(title);
    }
    if let Some(desc) = description {
        assessment.description = Set(Some(desc));
    }
    if let Some(time) = time_limit_minutes {
        assessment.time_limit_minutes = Set(time);
    }
    if let Some(open) = open_at {
        assessment.open_at = Set(open);
    }
    if let Some(close) = close_at {
        assessment.close_at = Set(close);
    }
    if let Some(show) = show_results_immediately {
        assessment.show_results_immediately = Set(show);
    }
    if let Some(q) = grading_period_number {
        assessment.grading_period_number = Set(q);
    }
    if let Some(c) = component {
        assessment.component = Set(c);
    }
    if let Some(tos) = tos_id {
        assessment.tos_id = Set(tos);
    }
    assessment.updated_at = Set(Utc::now().naive_utc());

    assessment
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update assessment: {}", e)))
}
