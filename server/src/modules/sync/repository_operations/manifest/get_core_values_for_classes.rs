use sea_orm::*;
use uuid::Uuid;

use ::entity::core_values_records;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_core_values_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    if class_ids.is_empty() {
        return Ok(PaginatedRecords { records: vec![] });
    }
    let query = core_values_records::Entity::find()
        .filter(core_values_records::Column::ClassId.is_in(class_ids));
    helpers::paginate_query(db, query, limit, |r| helpers::core_values_record_to_json(r))
        .await
}
