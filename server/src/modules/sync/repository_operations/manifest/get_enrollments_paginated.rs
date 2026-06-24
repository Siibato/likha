use sea_orm::*;
use uuid::Uuid;

use super::PaginatedRecords;
use crate::utils::{AppError, AppResult};
use ::entity::{class_participants, users};

pub async fn get_enrollments_paginated(
    db: &DatabaseConnection,
    enrollment_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = class_participants::Entity::find()
        .filter(class_participants::Column::Id.is_in(enrollment_ids));

    let all_records = query
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut result = Vec::new();
    for r in all_records {
        if let Ok(Some(user)) = users::Entity::find_by_id(r.user_id).one(db).await {
            if user.role == "student" {
                result.push(serde_json::json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "user_id": r.user_id.to_string(),
                    "student_id": r.user_id.to_string(),
                    "joined_at": r.joined_at.to_string(),
                    "enrolled_at": r.joined_at.to_string(),
                }));
                if result.len() >= limit as usize {
                    break;
                }
            }
        }
    }

    Ok(PaginatedRecords { records: result })
}
