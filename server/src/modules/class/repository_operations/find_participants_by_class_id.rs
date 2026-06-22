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
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    // Build user map before consuming participant_with_user
    let user_map: std::collections::HashMap<uuid::Uuid, users::Model> = participant_with_user
        .iter()
        .filter_map(|(p, u)| u.as_ref().map(|u| (p.user_id, u.clone())))
        .collect();

    let mut participants: Vec<class_participants::Model> = if let Some(role_filter) = role {
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

    participants.sort_by(|a, b| {
        let a_user = user_map.get(&a.user_id);
        let b_user = user_map.get(&b.user_id);
        match (a_user, b_user) {
            (Some(au), Some(bu)) => {
                let last_cmp = au.last_name.cmp(&bu.last_name);
                if last_cmp != std::cmp::Ordering::Equal {
                    return last_cmp;
                }
                au.first_name.cmp(&bu.first_name)
            }
            _ => std::cmp::Ordering::Equal,
        }
    });

    Ok(participants)
}
