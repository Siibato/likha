use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::utils::AppResult;
use super::save_answer_items::save_answer_items;

pub async fn save_enumeration_answers_linked(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
    items: Vec<(Option<Uuid>, String)>,
) -> AppResult<()> {
    let mapped = items.into_iter()
        .map(|(key_id, text)| (key_id, None, Some(text), false))
        .collect();
    save_answer_items(db, submission_answer_id, mapped).await
}
