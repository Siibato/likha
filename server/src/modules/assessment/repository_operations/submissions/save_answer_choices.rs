use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::save_answer_items::save_answer_items;
use crate::utils::AppResult;

pub async fn save_answer_choices(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
    choices: Vec<(Uuid, bool)>,
) -> AppResult<()> {
    let items = choices
        .into_iter()
        .map(|(choice_id, is_correct)| (None, Some(choice_id), None, is_correct))
        .collect();
    save_answer_items(db, submission_answer_id, items).await
}
