use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::classes;

pub async fn find_all(db: &DatabaseConnection) -> AppResult<Vec<classes::Model>> {
    classes::Entity::find()
        .filter(classes::Column::IsArchived.eq(false))
        .filter(classes::Column::DeletedAt.is_null())
        .order_by_desc(classes::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
