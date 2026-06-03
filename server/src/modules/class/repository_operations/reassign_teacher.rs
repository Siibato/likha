use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn reassign_teacher(db: &DatabaseConnection, class_id: Uuid, new_teacher_id: Uuid) -> AppResult<()> {
    let txn = db
        .begin()
        .await
        .map_err(|e| AppError::InternalServerError(format!("Transaction error: {}", e)))?;

    let participants = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .all(&txn)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    for participant in participants {
        if let Some(user) = users::Entity::find_by_id(participant.user_id)
            .one(&txn)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        {
            if user.role == "teacher" {
                let update = class_participants::ActiveModel {
                    id: Set(participant.id),
                    removed_at: Set(Some(Utc::now().naive_utc())),
                    updated_at: Set(Utc::now().naive_utc()),
                    ..Default::default()
                };
                update
                    .update(&txn)
                    .await
                    .map_err(|e| AppError::InternalServerError(format!("Failed to remove old teacher: {}", e)))?;
                break;
            }
        }
    }

    let existing = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::UserId.eq(new_teacher_id))
        .one(&txn)
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
            update
                .update(&txn)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to add new teacher: {}", e)))?;
        }
    } else {
        let participant = class_participants::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            user_id: Set(new_teacher_id),
            joined_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            removed_at: Set(None),
        };
        participant
            .insert(&txn)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add new teacher: {}", e)))?;
    }

    txn.commit()
        .await
        .map_err(|e| AppError::InternalServerError(format!("Transaction commit error: {}", e)))?;

    Ok(())
}
