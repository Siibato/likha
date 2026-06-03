use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::class_participants;
use crate::utils::AppResult;
use super::find_participants_by_user_id::find_participants_by_user_id;

pub async fn find_student_enrollments(db: &DatabaseConnection, student_id: Uuid) -> AppResult<Vec<class_participants::Model>> {
    find_participants_by_user_id(db, student_id, Some("student")).await
}
