use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::utils::AppResult;
use super::save_answer_items::save_answer_items;

pub async fn save_answer_choices(
    db: &DatabaseConnection,
    submission_answer_id: Uuid,
    choice_ids: Vec<Uuid>,
) -> AppResult<()> {
    let items = choice_ids.into_iter()
        .map(|choice_id| (None, Some(choice_id), None, false))
        .collect();
    save_answer_items(db, submission_answer_id, items).await
}
