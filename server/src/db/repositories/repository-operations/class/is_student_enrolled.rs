use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn is_student_enrolled(db: &DatabaseConnection, class_id: Uuid, student_id: Uuid) -> AppResult<bool> {
    let participant = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::UserId.eq(student_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if participant.is_some() {
        let user = users::Entity::find_by_id(student_id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        Ok(user.is_some() && user.unwrap().role == "student")
    } else {
        Ok(false)
    }
}
