use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn find_participants_with_users_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
    role: Option<&str>,
) -> AppResult<Vec<(class_participants::Model, users::Model)>> {
    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .order_by_asc(class_participants::Column::JoinedAt)
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let result: Vec<(class_participants::Model, users::Model)> = if let Some(role_filter) = role {
        participant_with_user
            .into_iter()
            .filter_map(|(participant, user)| {
                user.filter(|u| u.role == role_filter)
                    .map(|u| (participant, u))
            })
            .collect()
    } else {
        participant_with_user
            .into_iter()
            .filter_map(|(participant, user)| {
                user.map(|u| (participant, u))
            })
            .collect()
    };

    Ok(result)
}
