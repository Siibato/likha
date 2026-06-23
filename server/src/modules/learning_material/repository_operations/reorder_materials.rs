use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::learning_materials;

pub async fn reorder_materials(
    db: &DatabaseConnection,
    _class_id: Uuid,
    material_ids: Vec<Uuid>,
) -> AppResult<()> {
    for (index, id) in material_ids.iter().enumerate() {
        let material = learning_materials::ActiveModel {
            id: Set(*id),
            order_index: Set(index as i32),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };
        learning_materials::Entity::update(material)
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to reorder material: {}", e))
            })?;
    }
    Ok(())
}
