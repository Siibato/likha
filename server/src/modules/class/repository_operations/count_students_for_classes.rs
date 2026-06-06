use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};
use std::collections::HashMap;

pub async fn count_students_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<HashMap<Uuid, usize>> {
    if class_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let participant_with_user = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.is_in(class_ids))
        .filter(class_participants::Column::RemovedAt.is_null())
        .find_also_related(users::Entity)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut counts: HashMap<Uuid, usize> = HashMap::new();

    for (participant, user) in participant_with_user {
        if let Some(ref u) = user {
            if u.role == "student" {
                *counts.entry(participant.class_id).or_insert(0) += 1;
            }
        }
    }

    Ok(counts)
}
