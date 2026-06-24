use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assessments;

pub async fn reorder_assessments(
    db: &DatabaseConnection,
    _class_id: Uuid,
    assessment_ids: Vec<Uuid>,
) -> AppResult<()> {
    for (index, id) in assessment_ids.iter().enumerate() {
        let assessment = assessments::ActiveModel {
            id: Set(*id),
            order_index: Set(index as i32),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        assessments::Entity::update(assessment)
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to reorder assessment: {}", e))
            })?;
    }

    Ok(())
}
