use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::utils::AppResult;
use super::find_answer_items_by_submission_answer_id::find_answer_items_by_submission_answer_id;

pub async fn find_answer_choices(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
) -> AppResult<Vec<Uuid>> {
    let items = find_answer_items_by_submission_answer_id(db, submission_answer_id).await?;
    Ok(items.into_iter().filter_map(|item| item.choice_id).collect())
}
