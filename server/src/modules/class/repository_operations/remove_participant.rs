use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::class_participants;
use crate::utils::{AppError, AppResult};

pub async fn remove_participant(db: &DatabaseConnection, class_id: Uuid, user_id: Uuid) -> AppResult<()> {
    let participant = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::UserId.eq(user_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(participant) = participant {
        let update = class_participants::ActiveModel {
            id: Set(participant.id),
            removed_at: Set(Some(Utc::now().naive_utc())),
            ..Default::default()
        };
        update
            .update(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to remove participant: {}", e)))?;
    }

    Ok(())
}
