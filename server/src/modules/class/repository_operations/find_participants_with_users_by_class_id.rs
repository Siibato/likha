use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{class_participants, users};

pub async fn find_participants_with_users_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
    role: Option<&str>,
) -> AppResult<Vec<(class_participants::Model, users::Model)>> {
    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut result: Vec<(class_participants::Model, users::Model)> = if let Some(role_filter) = role
    {
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
            .filter_map(|(participant, user)| user.map(|u| (participant, u)))
            .collect()
    };

    result.sort_by(|a, b| {
        let last_cmp = a.1.last_name.cmp(&b.1.last_name);
        if last_cmp != std::cmp::Ordering::Equal {
            return last_cmp;
        }
        a.1.first_name.cmp(&b.1.first_name)
    });

    Ok(result)
}
