use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::find_participants_by_user_id::find_participants_by_user_id;
use crate::utils::AppResult;
use ::entity::class_participants;

pub async fn find_student_enrollments(
    db: &DatabaseConnection,
    student_id: Uuid,
) -> AppResult<Vec<class_participants::Model>> {
    find_participants_by_user_id(db, student_id, Some("student")).await
}
