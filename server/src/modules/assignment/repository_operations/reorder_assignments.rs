use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::assignments;

pub async fn reorder_assignments(
    db: &DatabaseConnection,
    _class_id: Uuid,
    assignment_ids: Vec<Uuid>,
) -> AppResult<()> {
    for (index, id) in assignment_ids.iter().enumerate() {
        let assignment = assignments::ActiveModel {
            id: Set(*id),
            order_index: Set(index as i32),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        assignments::Entity::update(assignment)
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to reorder assignment: {}", e))
            })?;
    }

    Ok(())
}
