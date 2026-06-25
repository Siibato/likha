use sea_orm::{DatabaseConnection, EntityTrait, Set};

use crate::seed::specs::AssignmentSpec;
use crate::utils::AppError;
use ::entity::assignments;

const CHUNK_SIZE: usize = 100;

pub async fn insert_assignments(
    db: &DatabaseConnection,
    specs: &[AssignmentSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let models: Vec<assignments::ActiveModel> = specs
        .iter()
        .map(|spec| assignments::ActiveModel {
            id: Set(spec.id),
            class_id: Set(spec.class_id),
            title: Set(spec.title.clone()),
            instructions: Set(spec.instructions.clone()),
            total_points: Set(spec.total_points),
            allows_text_submission: Set(spec.allows_text_submission),
            allows_file_submission: Set(spec.allows_file_submission),
            allowed_file_types: Set(None),
            max_file_size_mb: Set(None),
            due_at: Set(spec.due_at),
            is_published: Set(spec.is_published && spec.deleted_at.is_none()),
            order_index: Set(0),
            created_at: Set(spec.created_at),
            updated_at: Set(spec.created_at),
            deleted_at: Set(spec.deleted_at),
            term_number: Set(Some(spec.term_number)),
            component: Set(Some(spec.component.clone())),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        assignments::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
