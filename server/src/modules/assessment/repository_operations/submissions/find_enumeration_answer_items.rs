use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::find_answer_items_by_submission_answer_id::find_answer_items_by_submission_answer_id;
use crate::utils::AppResult;
use ::entity::submission_answer_items;

pub async fn find_enumeration_answer_items(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
) -> AppResult<Vec<submission_answer_items::Model>> {
    let items = find_answer_items_by_submission_answer_id(db, submission_answer_id).await?;
    Ok(items
        .into_iter()
        .filter(|i| i.answer_text.is_some())
        .collect())
}
