use sea_orm::*;
use uuid::Uuid;

use ::entity::table_of_specifications;
use crate::utils::{AppError, AppResult};

pub async fn find_tos_by_class_and_period(
    db: &DatabaseConnection,
    class_id: Uuid,
    term_number: i32,
) -> AppResult<Vec<table_of_specifications::Model>> {
    table_of_specifications::Entity::find()
        .filter(table_of_specifications::Column::ClassId.eq(class_id))
        .filter(table_of_specifications::Column::TermNumber.eq(term_number))
        .filter(table_of_specifications::Column::DeletedAt.is_null())
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
