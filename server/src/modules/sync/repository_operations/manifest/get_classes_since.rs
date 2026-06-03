use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::classes;
use crate::utils::{AppError, AppResult};
use super::helpers;

pub async fn get_classes_since(
    db: &DatabaseConnection,
    class_ids: Vec<Uuid>,
    since: NaiveDateTime,
) -> AppResult<Vec<Value>> {
    if class_ids.is_empty() {
        return Ok(vec![]);
    }

    let records = classes::Entity::find()
        .filter(classes::Column::Id.is_in(class_ids.clone()))
        .filter(classes::Column::UpdatedAt.gt(since))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let teacher_map = helpers::build_teacher_map(db, &class_ids).await?;

    let records: Vec<Value> = records
        .into_iter()
        .map(move |r| {
            let (teacher_id, teacher_username, teacher_full_name) = teacher_map
                .get(&r.id)
                .map(|t| (t.0.to_string(), t.1.clone(), t.2.clone()))
                .unwrap_or_else(|| ("".to_string(), "".to_string(), "".to_string()));

            serde_json::json!({
                "id": r.id.to_string(),
                "title": r.title,
                "description": r.description,
                "is_archived": r.is_archived,
                "is_advisory": r.is_advisory,
                "grading_period_type": r.grading_period_type,
                "grade_level": r.grade_level,
                "school_year": r.school_year,
                "teacher_id": teacher_id,
                "teacher_username": teacher_username,
                "teacher_full_name": teacher_full_name,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
                "student_count": 0,
            })
        })
        .collect();

    Ok(records)
}
