use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, classes};
use crate::utils::{AppError, AppResult};

pub async fn get_user_accessible_classes(
    db: &DatabaseConnection,
    user_id: Uuid,
    user_role: &str,
) -> AppResult<Vec<Uuid>> {
    match user_role {
        "student" | "teacher" => {
            let participants = class_participants::Entity::find()
                .filter(class_participants::Column::UserId.eq(user_id))
                .filter(class_participants::Column::RemovedAt.is_null())
                .all(db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

            Ok(participants.iter().map(|p| p.class_id).collect())
        }
        "admin" => {
            let classes = classes::Entity::find()
                .all(db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

            Ok(classes.iter().map(|c| c.id).collect())
        }
        _ => Err(AppError::BadRequest(format!("Invalid role: {}", user_role))),
    }
}
