use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::learner_details;

pub async fn get_learner_details_for_students(
    db: &DatabaseConnection,
    student_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if student_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }
    let query = learner_details::Entity::find()
        .filter(learner_details::Column::UserId.is_in(student_ids))
        .filter(learner_details::Column::DeletedAt.is_null());
    helpers::paginate_query(db, query, limit, |r| helpers::learner_details_to_json(r)).await
}
