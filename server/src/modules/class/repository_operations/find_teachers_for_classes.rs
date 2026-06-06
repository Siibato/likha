use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn find_teachers_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<(Uuid, users::Model)>> {
    if class_ids.is_empty() {
        return Ok(vec![]);
    }

    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.is_in(class_ids))
        .filter(class_participants::Column::RemovedAt.is_null())
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut result: Vec<(Uuid, users::Model)> = Vec::new();
    let mut seen_class_ids = std::collections::HashSet::new();

    for (participant, user) in participant_with_user {
        if let Some(ref u) = user {
            if u.role == "teacher" && !seen_class_ids.contains(&participant.class_id) {
                seen_class_ids.insert(participant.class_id);
                result.push((participant.class_id, u.clone()));
            }
        }
    }

    Ok(result)
}
