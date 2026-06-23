use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};

use crate::seed::specs::MaterialSpec;
use crate::utils::AppError;
use ::entity::learning_materials;

pub async fn insert_materials(
    db: &DatabaseConnection,
    specs: &[MaterialSpec],
) -> Result<(), AppError> {
    for spec in specs {
        let model = learning_materials::ActiveModel {
            id: Set(spec.id),
            class_id: Set(spec.class_id),
            title: Set(spec.title.clone()),
            description: Set(spec.description.clone()),
            content_text: Set(spec.content_text.clone()),
            order_index: Set(spec.order_index),
            created_at: Set(spec.created_at),
            updated_at: Set(spec.created_at),
            deleted_at: Set(None),
        };
        model
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }
    Ok(())
}
