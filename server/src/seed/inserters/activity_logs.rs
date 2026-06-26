use sea_orm::{DatabaseConnection, EntityTrait, Set};

use crate::seed::specs::ActivityLogSpec;
use crate::utils::AppError;
use ::entity::activity_logs;

const CHUNK_SIZE: usize = 100;

pub async fn insert_activity_logs(
    db: &DatabaseConnection,
    specs: &[ActivityLogSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let models: Vec<activity_logs::ActiveModel> = specs
        .iter()
        .map(|spec| activity_logs::ActiveModel {
            id: Set(spec.id),
            user_id: Set(spec.user_id),
            action: Set(spec.action.clone()),
            details: Set(spec.details.clone()),
            created_at: Set(spec.created_at),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        activity_logs::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
