use sea_orm::*;
use uuid::Uuid;

use ::entity::student_school_history;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_school_history_for_students(
    db: &DatabaseConnection,
    student_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if student_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }
    let query = student_school_history::Entity::find()
        .filter(student_school_history::Column::StudentId.is_in(student_ids));
    helpers::paginate_query(db, query, limit, |r| helpers::school_history_to_json(r))
        .await
}
