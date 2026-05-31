use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::class_participants;
use crate::utils::{AppError, AppResult};

pub async fn remove_all_participants(db: &DatabaseConnection, class_id: Uuid) -> AppResult<()> {
    let participants = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let now = Utc::now().naive_utc();
    for participant in participants {
        let update = class_participants::ActiveModel {
            id: Set(participant.id),
            removed_at: Set(Some(now)),
            updated_at: Set(now),
            ..Default::default()
        };
        update
            .update(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to remove participant: {}", e)))?;
    }

    Ok(())
}
