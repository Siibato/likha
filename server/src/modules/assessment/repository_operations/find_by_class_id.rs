use sea_orm::*;
use uuid::Uuid;

use ::entity::assessments;
use crate::utils::{AppError, AppResult};

pub async fn find_by_class_id(
    db: &DatabaseConnection,
    class_id: Uuid,
) -> AppResult<Vec<assessments::Model>> {
    assessments::Entity::find()
        .filter(assessments::Column::ClassId.eq(class_id))
        .filter(assessments::Column::DeletedAt.is_null())
        .order_by_asc(assessments::Column::OrderIndex)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
