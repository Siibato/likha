use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::core_values_records;

pub async fn get_core_values(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Option<Uuid>,
    school_year: Option<&str>,
) -> AppResult<Vec<core_values_records::Model>> {
    let mut query = core_values_records::Entity::find()
        .filter(core_values_records::Column::StudentId.eq(student_id))
        .filter(core_values_records::Column::DeletedAt.is_null());

    if let Some(cid) = class_id {
        query = query.filter(core_values_records::Column::ClassId.eq(cid));
    }
    if let Some(sy) = school_year {
        query = query.filter(core_values_records::Column::SchoolYear.eq(sy));
    }

    query
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
