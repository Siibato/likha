use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::material_files;
use crate::utils::{AppError, AppResult};

pub async fn save_file(
    db: &DatabaseConnection,
    material_id: Uuid,
    file_name: String,
    file_type: String,
    file_size: i64,
    file_path: String,
    file_hash: String,
) -> AppResult<material_files::Model> {
    let file = material_files::ActiveModel {
        id: Set(Uuid::new_v4()),
        material_id: Set(material_id),
        file_name: Set(file_name),
        file_type: Set(file_type),
        file_size: Set(file_size),
        file_path: Set(Some(file_path)),
        file_hash: Set(Some(file_hash)),
        uploaded_at: Set(Utc::now().naive_utc()),
        deleted_at: Set(None),
    };

    file.insert(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to save file: {}", e)))
}
