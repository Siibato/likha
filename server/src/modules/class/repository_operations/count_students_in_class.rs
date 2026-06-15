use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn count_students_in_class(db: &DatabaseConnection, class_id: Uuid) -> AppResult<usize> {
    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let count = participant_with_user
        .into_iter()
        .filter(|(_participant, user)| {
            user.as_ref().map_or(false, |u| u.role == "student")
        })
        .count();

    Ok(count)
}
