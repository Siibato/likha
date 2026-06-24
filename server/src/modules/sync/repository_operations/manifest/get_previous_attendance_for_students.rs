use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::previous_school_attendance;

pub async fn get_previous_attendance_for_students(
    db: &DatabaseConnection,
    student_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if student_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }
    let query = previous_school_attendance::Entity::find()
        .filter(previous_school_attendance::Column::StudentId.is_in(student_ids));
    helpers::paginate_query(db, query, limit, |r| {
        helpers::previous_school_attendance_to_json(r)
    })
    .await
}
