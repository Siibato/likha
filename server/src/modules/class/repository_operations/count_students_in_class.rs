use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::utils::AppResult;
use super::find_participants_by_class_id::find_participants_by_class_id;

pub async fn count_students_in_class(db: &DatabaseConnection, class_id: Uuid) -> AppResult<usize> {
    let students = find_participants_by_class_id(db, class_id, Some("student")).await?;
    Ok(students.len())
}
