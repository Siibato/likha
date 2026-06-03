use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn find_teacher_of_class(db: &DatabaseConnection, class_id: Uuid) -> AppResult<Option<users::Model>> {
    let participants = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    for participant in participants {
        if let Some(user) = users::Entity::find_by_id(participant.user_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
            if user.role == "teacher" {
                return Ok(Some(user));
            }
        }
    }
    Ok(None)
}
