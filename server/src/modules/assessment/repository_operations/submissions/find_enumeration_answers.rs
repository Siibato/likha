use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::find_answer_items_by_submission_answer_id::find_answer_items_by_submission_answer_id;
use crate::utils::AppResult;

pub async fn find_enumeration_answers(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
) -> AppResult<Vec<String>> {
    let items = find_answer_items_by_submission_answer_id(db, submission_answer_id).await?;
    Ok(items
        .into_iter()
        .filter_map(|item| item.answer_text)
        .collect())
}
