use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{class_participants, users};

pub async fn find_teacher_of_class(
    db: &DatabaseConnection,
    class_id: Uuid,
) -> AppResult<Option<users::Model>> {
    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    for (_participant, user) in participant_with_user {
        if let Some(ref u) = user {
            if u.role == "teacher" {
                return Ok(Some(u.clone()));
            }
        }
    }
    Ok(None)
}
