use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn is_teacher_of_class(
    db: &DatabaseConnection,
    teacher_id: Uuid,
    class_id: Uuid,
) -> AppResult<bool> {
    let participant = class_participants::Entity::find()
        .filter(class_participants::Column::UserId.eq(teacher_id))
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if participant.is_some() {
        if let Some(user) = users::Entity::find_by_id(teacher_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        {
            return Ok(user.role == "teacher");
        }
    }
    Ok(false)
}
