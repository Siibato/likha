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
    tracing::info!("bulk_upsert_scores: grade_item_id={} scores_count={}", grade_item_id, scores.len());
    let grade_item_exists = grade_items::Entity::find_by_id(grade_item_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error checking grade item: {}", e)))?
        .is_some();

    if !grade_item_exists {
        tracing::error!("bulk_upsert_scores: grade_item_id={} does not exist", grade_item_id);
        return Err(AppError::BadRequest(format!("Grade item {} does not exist", grade_item_id)));
    }

    for (student_id, score) in &scores {
        upsert_score(db, grade_item_id, *student_id, Some(*score), false).await?;
    }

    tracing::info!("bulk_upsert_scores: grade_item_id={} scores_saved={}", grade_item_id, scores.len());
    Ok(())
}
