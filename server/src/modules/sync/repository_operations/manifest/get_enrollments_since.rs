use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{class_participants, users};

pub async fn get_enrollments_since(
    db: &DatabaseConnection,
    enrollment_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    let participants = class_participants::Entity::find()
        .filter(class_participants::Column::Id.is_in(enrollment_ids))
        .filter(class_participants::Column::JoinedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut records: Vec<Value> = Vec::new();
    for r in participants {
        if let Ok(Some(user)) = users::Entity::find_by_id(r.user_id).one(db).await {
            if user.role == "student" {
                records.push(serde_json::json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "user_id": r.user_id.to_string(),
                    "student_id": r.user_id.to_string(),
                    "joined_at": r.joined_at.to_string(),
                    "enrolled_at": r.joined_at.to_string(),
                    "removed_at": r.removed_at.map(|d| d.to_string()),
                }));
            }
        }
    }

    Ok(records)
}
