use sea_orm::*;
use uuid::Uuid;

use super::ManifestEntry;
use crate::utils::{AppError, AppResult};
use ::entity::{class_participants, users};

pub async fn get_enrollments_manifest(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    user_id: Uuid,
    user_role: &str,
) -> AppResult<Vec<ManifestEntry>> {
    let mut query = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.is_in(class_ids))
        .filter(class_participants::Column::RemovedAt.is_null());

    if user_role == "student" {
        query = query.filter(class_participants::Column::UserId.eq(user_id));
    }

    let participants = query
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut result = Vec::new();
    for p in participants {
        if let Ok(Some(user)) = users::Entity::find_by_id(p.user_id).one(db).await {
            if user.role == "student" {
                result.push(ManifestEntry {
                    id: p.id,
                    updated_at: p.joined_at,
                    deleted: p.removed_at.is_some(),
                });
            }
        }
    }

    Ok(result)
}
