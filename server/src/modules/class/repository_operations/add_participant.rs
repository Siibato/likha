use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::class_participants;

pub async fn add_participant(
    db: &DatabaseConnection,
    class_id: Uuid,
    user_id: Uuid,
) -> AppResult<class_participants::Model> {
    let existing = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::UserId.eq(user_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(existing_participant) = existing {
        if existing_participant.removed_at.is_some() {
            let update = class_participants::ActiveModel {
                id: Set(existing_participant.id),
                removed_at: Set(None),
                updated_at: Set(Utc::now().naive_utc()),
                ..Default::default()
            };
            return update.update(db).await.map_err(|e| {
                AppError::InternalServerError(format!("Failed to add participant: {}", e))
            });
        }
        return Ok(existing_participant);
    }

    let participant = class_participants::ActiveModel {
        id: Set(Uuid::new_v4()),
        class_id: Set(class_id),
        user_id: Set(user_id),
        joined_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
        removed_at: Set(None),
    };

    participant
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to add participant: {}", e)))
}
