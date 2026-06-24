use sea_orm::*;
use uuid::Uuid;

use super::{helpers, PaginatedRecords};
use crate::utils::AppResult;
use ::entity::attendance_records;

pub async fn get_attendance_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if class_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }
    let query = attendance_records::Entity::find()
        .filter(attendance_records::Column::ClassId.is_in(class_ids));
    helpers::paginate_query(db, query, limit, |r| helpers::attendance_record_to_json(r)).await
}
