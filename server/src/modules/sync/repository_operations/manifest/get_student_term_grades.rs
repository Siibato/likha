use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::term_grades;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_student_term_grades(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_ids: Vec<Uuid>,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() { return Ok(vec![]); }
    let records = term_grades::Entity::find()
        .filter(term_grades::Column::ClassId.is_in(class_ids))
        .filter(term_grades::Column::StudentId.eq(student_id))
        .all(db).await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(records.into_iter().map(helpers::term_grade_to_json).collect())
}
