use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::teacher_details;

pub async fn get_teacher_details_for_teachers(
    db: &DatabaseConnection,
    teacher_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if teacher_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }
    let query = teacher_details::Entity::find()
        .filter(teacher_details::Column::UserId.is_in(teacher_ids))
        .filter(teacher_details::Column::DeletedAt.is_null());
    helpers::paginate_query(db, query, limit, |r| helpers::teacher_details_to_json(r)).await
}
