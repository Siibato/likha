use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{grade_items, grade_scores, users};
use crate::utils::{AppError, AppResult};

pub async fn upsert_score(
    db: &DatabaseConnection,
    grade_item_id: Uuid,
    student_id: Uuid,
    score: Option<f64>,
    is_auto_populated: bool,
) -> AppResult<grade_scores::Model> {
    let now = Utc::now().naive_utc();
    let id = Uuid::new_v4();

    let grade_item_exists = grade_items::Entity::find_by_id(grade_item_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error checking grade item: {}", e)))?
        .is_some();

    if !grade_item_exists {
        return Err(AppError::BadRequest(format!("Grade item {} does not exist", grade_item_id)));
    }

    let student_exists = users::Entity::find_by_id(student_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error checking student: {}", e)))?
        .is_some();

    if !student_exists {
        return Err(AppError::BadRequest(format!("Student {} does not exist", student_id)));
    }

    let sql = r#"
        INSERT INTO grade_scores (id, grade_item_id, student_id, score, is_auto_populated, override_score, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, (SELECT override_score FROM grade_scores WHERE grade_item_id = ? AND student_id = ?), ?, ?)
        ON CONFLICT(grade_item_id, student_id) DO UPDATE SET
            score = excluded.score,
            is_auto_populated = excluded.is_auto_populated,
            updated_at = excluded.updated_at
    "#;

    let stmt = Statement::from_sql_and_values(
        DbBackend::Sqlite,
        sql,
        vec![
            id.to_string().into(),
            grade_item_id.to_string().into(),
            student_id.to_string().into(),
            score.map(Value::from).unwrap_or(Value::Double(None)),
            is_auto_populated.into(),
            grade_item_id.to_string().into(),
            student_id.to_string().into(),
            now.to_string().into(),
            now.to_string().into(),
        ],
    );

    db.execute(stmt)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to upsert score: {}", e)))?;

    grade_scores::Entity::find()
        .filter(grade_scores::Column::GradeItemId.eq(grade_item_id))
        .filter(grade_scores::Column::StudentId.eq(student_id))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .ok_or_else(|| AppError::InternalServerError("Score not found after upsert".to_string()))
}
