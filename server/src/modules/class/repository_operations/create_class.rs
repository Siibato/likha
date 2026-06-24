use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::classes;

pub async fn create_class(
    db: &DatabaseConnection,
    title: String,
    description: Option<String>,
    client_id: Option<Uuid>,
    is_advisory: bool,
) -> AppResult<classes::Model> {
    let class_id = client_id.unwrap_or_else(Uuid::new_v4);
    let now = Utc::now().naive_utc();
    let class = classes::ActiveModel {
        id: Set(class_id),
        title: Set(title),
        description: Set(description),
        is_archived: Set(false),
        created_at: Set(now),
        updated_at: Set(now),
        deleted_at: Set(None),
        grade_level: Set(None),
        school_year: Set(None),
        term_type: Set("term".to_string()),
        is_advisory: Set(is_advisory),
    };

    class
        .insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to create class: {}", e)))
}
