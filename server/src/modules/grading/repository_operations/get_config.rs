use sea_orm::*;
use uuid::Uuid;

use ::entity::grade_record;
use crate::utils::{AppError, AppResult};

pub async fn get_config(
    db: &DatabaseConnection,
    class_id: Uuid,
    term_number: i32,
) -> AppResult<Option<grade_record::Model>> {
    grade_record::Entity::find()
        .filter(grade_record::Column::ClassId.eq(class_id))
        .filter(grade_record::Column::TermNumber.eq(term_number))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
