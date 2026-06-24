use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::student_school_history;

pub async fn delete_school_history(db: &DatabaseConnection, id: Uuid) -> AppResult<()> {
    student_school_history::Entity::delete_by_id(id)
        .exec(db)
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to delete school history: {}", e))
        })?;
    Ok(())
}
