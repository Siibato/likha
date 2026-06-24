use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::material_files;

pub async fn get_material_files_for_materials(
    db: &DatabaseConnection,
    material_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    let files = material_files::Entity::find()
        .filter(material_files::Column::MaterialId.is_in(material_ids))
        .all(db)
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to fetch material files: {}", e))
        })?;
    Ok(files
        .into_iter()
        .map(|f| {
            serde_json::json!({
                "id": f.id.to_string(),
                "material_id": f.material_id.to_string(),
                "file_name": f.file_name,
                "file_type": f.file_type,
                "file_size": f.file_size,
                "uploaded_at": f.uploaded_at.to_string(),
            })
        })
        .collect())
}
