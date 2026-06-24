use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::grade_scores;

pub async fn get_scores_by_item(
    db: &DatabaseConnection,
    grade_item_id: Uuid,
) -> AppResult<Vec<grade_scores::Model>> {
    grade_scores::Entity::find()
        .filter(grade_scores::Column::GradeItemId.eq(grade_item_id))
        .filter(grade_scores::Column::DeletedAt.is_null())
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
