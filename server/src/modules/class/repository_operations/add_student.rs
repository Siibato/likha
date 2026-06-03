use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::class_participants;
use crate::utils::AppResult;
use super::add_participant::add_participant;

pub async fn add_student(db: &DatabaseConnection, class_id: Uuid, student_id: Uuid) -> AppResult<class_participants::Model> {
    add_participant(db, class_id, student_id).await
}
