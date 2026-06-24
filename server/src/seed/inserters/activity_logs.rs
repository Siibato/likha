use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};

use crate::seed::specs::ActivityLogSpec;
use crate::utils::AppError;
use ::entity::activity_logs;

pub async fn insert_activity_logs(
    db: &DatabaseConnection,
    specs: &[ActivityLogSpec],
) -> Result<(), AppError> {
    for spec in specs {
        let log = activity_logs::ActiveModel {
            id: Set(spec.id),
            user_id: Set(spec.user_id),
            action: Set(spec.action.clone()),
            details: Set(spec.details.clone()),
            created_at: Set(spec.created_at),
        };
        log.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }
    Ok(())
}
