use sea_orm::{DatabaseConnection, EntityTrait, Set};

use crate::seed::specs::MaterialSpec;
use crate::utils::AppError;
use ::entity::learning_materials;

const CHUNK_SIZE: usize = 100;

pub async fn insert_materials(
    db: &DatabaseConnection,
    specs: &[MaterialSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let models: Vec<learning_materials::ActiveModel> = specs
        .iter()
        .map(|spec| learning_materials::ActiveModel {
            id: Set(spec.id),
            class_id: Set(spec.class_id),
            title: Set(spec.title.clone()),
            description: Set(spec.description.clone()),
            content_text: Set(spec.content_text.clone()),
            order_index: Set(spec.order_index),
            created_at: Set(spec.created_at),
            updated_at: Set(spec.created_at),
            deleted_at: Set(None),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        learning_materials::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
