use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::find_by_user_id::find_by_user_id;
use crate::utils::AppResult;
use ::entity::classes;

pub async fn find_classes_by_student_id(
    db: &DatabaseConnection,
    student_id: Uuid,
) -> AppResult<Vec<classes::Model>> {
    find_by_user_id(db, student_id, "student").await
}
