use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessments;

pub async fn soft_delete(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    let assessment = assessments::ActiveModel {
        id: Set(id),
        deleted_at: Set(Some(Utc::now().naive_utc())),
        updated_at: Set(Utc::now().naive_utc()),
        ..Default::default()
    };

    assessments::Entity::update(assessment)
        .exec(db)
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to delete assessment: {}", e))
        })?;

    Ok(())
}
