use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{class_participants, users};

pub async fn find_participants_by_user_id(
    db: &DatabaseConnection,
    user_id: Uuid,
    role: Option<&str>,
) -> AppResult<Vec<class_participants::Model>> {
    let mut participants = class_participants::Entity::find()
        .filter(class_participants::Column::UserId.eq(user_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .order_by_asc(class_participants::Column::JoinedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if let Some(role_filter) = role {
        let user = users::Entity::find_by_id(user_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(user) = user {
            if user.role != role_filter {
                participants.clear();
            }
        } else {
            participants.clear();
        }
    }

    Ok(participants)
}
