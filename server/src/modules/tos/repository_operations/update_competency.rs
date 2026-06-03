use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::tos_competencies;
use crate::utils::{AppError, AppResult};

pub async fn update_competency(
    db: &DatabaseConnection,
    id: Uuid,
    competency_code: Option<Option<&str>>,
    competency_text: Option<&str>,
    time_units_taught: Option<i32>,
    order_index: Option<i32>,
    easy_count: Option<Option<i32>>,
    medium_count: Option<Option<i32>>,
    hard_count: Option<Option<i32>>,
    remembering_count: Option<Option<i32>>,
    understanding_count: Option<Option<i32>>,
    applying_count: Option<Option<i32>>,
    analyzing_count: Option<Option<i32>>,
    evaluating_count: Option<Option<i32>>,
    creating_count: Option<Option<i32>>,
) -> AppResult<tos_competencies::Model> {
    let comp = tos_competencies::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

    let mut active: tos_competencies::ActiveModel = comp.into();

    if let Some(code) = competency_code { active.competency_code = Set(code.map(|s| s.to_string())); }
    if let Some(text) = competency_text { active.competency_text = Set(text.to_string()); }
    if let Some(units) = time_units_taught { active.time_units_taught = Set(units); }
    if let Some(idx) = order_index { active.order_index = Set(idx); }
    if let Some(e) = easy_count { active.easy_count = Set(e); }
    if let Some(m) = medium_count { active.medium_count = Set(m); }
    if let Some(h) = hard_count { active.hard_count = Set(h); }
    if let Some(r) = remembering_count { active.remembering_count = Set(r); }
    if let Some(u) = understanding_count { active.understanding_count = Set(u); }
    if let Some(ap) = applying_count { active.applying_count = Set(ap); }
    if let Some(an) = analyzing_count { active.analyzing_count = Set(an); }
    if let Some(e) = evaluating_count { active.evaluating_count = Set(e); }
    if let Some(c) = creating_count { active.creating_count = Set(c); }
    active.updated_at = Set(Utc::now().naive_utc());

    active
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update competency: {}", e)))
}
