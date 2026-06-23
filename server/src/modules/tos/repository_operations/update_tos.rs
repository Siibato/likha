use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::table_of_specifications;

pub async fn update_tos(
    db: &DatabaseConnection,
    id: Uuid,
    title: Option<&str>,
    classification_mode: Option<&str>,
    total_items: Option<i32>,
    time_unit: Option<&str>,
    easy_percentage: Option<f64>,
    medium_percentage: Option<f64>,
    hard_percentage: Option<f64>,
    remembering_percentage: Option<f64>,
    understanding_percentage: Option<f64>,
    applying_percentage: Option<f64>,
    analyzing_percentage: Option<f64>,
    evaluating_percentage: Option<f64>,
    creating_percentage: Option<f64>,
) -> AppResult<table_of_specifications::Model> {
    let tos = table_of_specifications::Entity::find_by_id(id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    let mut active: table_of_specifications::ActiveModel = tos.into();

    if let Some(t) = title {
        active.title = Set(t.to_string());
    }
    if let Some(m) = classification_mode {
        active.classification_mode = Set(m.to_string());
    }
    if let Some(n) = total_items {
        active.total_items = Set(n);
    }
    if let Some(u) = time_unit {
        active.time_unit = Set(u.to_string());
    }
    if let Some(e) = easy_percentage {
        active.easy_percentage = Set(e);
    }
    if let Some(m) = medium_percentage {
        active.medium_percentage = Set(m);
    }
    if let Some(h) = hard_percentage {
        active.hard_percentage = Set(h);
    }
    if let Some(r) = remembering_percentage {
        active.remembering_percentage = Set(r);
    }
    if let Some(u) = understanding_percentage {
        active.understanding_percentage = Set(u);
    }
    if let Some(ap) = applying_percentage {
        active.applying_percentage = Set(ap);
    }
    if let Some(an) = analyzing_percentage {
        active.analyzing_percentage = Set(an);
    }
    if let Some(e) = evaluating_percentage {
        active.evaluating_percentage = Set(e);
    }
    if let Some(c) = creating_percentage {
        active.creating_percentage = Set(c);
    }
    active.updated_at = Set(Utc::now().naive_utc());

    active
        .update(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to update TOS: {}", e)))
}
