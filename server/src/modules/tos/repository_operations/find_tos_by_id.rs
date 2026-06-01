use sea_orm::*;
use uuid::Uuid;

use ::entity::table_of_specifications;
use crate::utils::{AppError, AppResult};

pub async fn find_tos_by_id(
    db: &DatabaseConnection,
    id: Uuid,
) -> AppResult<Option<table_of_specifications::Model>> {
    table_of_specifications::Entity::find_by_id(id)
        .filter(table_of_specifications::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
