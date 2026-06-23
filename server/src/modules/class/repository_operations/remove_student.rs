use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::remove_participant::remove_participant;
use crate::utils::AppResult;

pub async fn remove_student(
    db: &DatabaseConnection,
    class_id: Uuid,
    student_id: Uuid,
) -> AppResult<()> {
    remove_participant(db, class_id, student_id).await
}
