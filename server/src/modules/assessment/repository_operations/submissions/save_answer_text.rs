use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::save_answer_items::save_answer_items;
use crate::utils::AppResult;

pub async fn save_answer_text(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
    answer_text: String,
) -> AppResult<()> {
    let items = vec![(None, None, Some(answer_text), false)];
    save_answer_items(db, submission_answer_id, items).await
}
