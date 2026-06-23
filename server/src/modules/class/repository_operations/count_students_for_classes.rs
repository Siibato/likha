use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::class_participants;
use std::collections::HashMap;

pub async fn count_students_for_classes(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
) -> AppResult<HashMap<Uuid, usize>> {
    if class_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let rows: Vec<(Uuid, i64)> = class_participants::Entity::find()
        .select_only()
        .column(class_participants::Column::ClassId)
        .column_as(class_participants::Column::Id.count(), "count")
        .filter(class_participants::Column::ClassId.is_in(class_ids))
        .filter(class_participants::Column::RemovedAt.is_null())
        .group_by(class_participants::Column::ClassId)
        .into_tuple()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(rows
        .into_iter()
        .map(|(id, count)| (id, count as usize))
        .collect())
}
