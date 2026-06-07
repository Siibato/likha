use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn find_participants_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
    role: Option<&str>,
) -> AppResult<Vec<class_participants::Model>> {
    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .order_by_asc(class_participants::Column::JoinedAt)
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let participants: Vec<class_participants::Model> = if let Some(role_filter) = role {
        participant_with_user
            .into_iter()
            .filter(|(_participant, user)| {
                user.as_ref().map_or(false, |u| u.role == role_filter)
            })
            .map(|(participant, _user)| participant)
            .collect()
    } else {
        participant_with_user
            .into_iter()
            .map(|(participant, _user)| participant)
            .collect()
    };

    Ok(participants)
}
