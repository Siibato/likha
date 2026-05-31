use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn find_participants_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
    role: Option<&str>,
) -> AppResult<Vec<class_participants::Model>> {
    let mut participants = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .order_by_asc(class_participants::Column::JoinedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(role_filter) = role {
        let mut filtered = Vec::new();
        for participant in participants {
            if let Some(user) = users::Entity::find_by_id(participant.user_id)
                .one(db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                if user.role == role_filter {
                    filtered.push(participant);
                }
            }
        }
        participants = filtered;
    }

    Ok(participants)
}
