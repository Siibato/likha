use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::grade_items;
use sea_orm::*;
use crate::utils::{AppError, AppResult};
use super::upsert_score::upsert_score;

pub async fn bulk_upsert_scores(
    db: &DatabaseConnection,
    grade_item_id: Uuid,
    scores: Vec<(Uuid, f64)>,
) -> AppResult<()> {
    let grade_item_exists = grade_items::Entity::find_by_id(grade_item_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error checking grade item: {}", e)))?
        .is_some();

    if !grade_item_exists {
        return Err(AppError::BadRequest(format!("Grade item {} does not exist", grade_item_id)));
    }

    for (student_id, score) in scores {
        match upsert_score(db, grade_item_id, student_id, Some(score), false).await {
            Ok(_) => {}
            Err(e) => {
                tracing::warn!(
                    "Failed to save score for student {} in grade item {}: {}",
                    student_id, grade_item_id, e
                );
            }
        }
    }

    Ok(())
}
