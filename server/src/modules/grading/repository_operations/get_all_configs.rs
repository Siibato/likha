use sea_orm::*;
use uuid::Uuid;

use ::entity::grade_record;
use crate::utils::{AppError, AppResult};

pub async fn get_all_configs(
    db: &DatabaseConnection,
    class_id: Uuid,
) -> AppResult<Vec<grade_record::Model>> {
    grade_record::Entity::find()
        .filter(grade_record::Column::ClassId.eq(class_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
