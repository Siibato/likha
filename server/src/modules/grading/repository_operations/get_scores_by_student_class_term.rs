use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::grade_scores;

pub async fn get_scores_by_student_class_term(
    db: &DatabaseConnection,
    student_id: Uuid,
    class_id: Uuid,
    term_number: i32,
) -> AppResult<Vec<grade_scores::Model>> {
    let sql = r#"
        SELECT gs.id, gs.grade_item_id, gs.student_id, gs.score,
               gs.is_auto_populated, gs.override_score,
               gs.created_at, gs.updated_at, gs.deleted_at
        FROM grade_scores gs
        INNER JOIN grade_items gi ON gs.grade_item_id = gi.id
        WHERE gs.student_id = ?
          AND gi.class_id = ?
          AND gi.term_number = ?
          AND gs.deleted_at IS NULL
          AND gi.deleted_at IS NULL
    "#;

    let stmt = Statement::from_sql_and_values(
        DbBackend::Sqlite,
        sql,
        vec![student_id.into(), class_id.into(), term_number.into()],
    );

    let rows = db
        .query_all(stmt)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut scores = Vec::new();
    for row in rows {
        let id: String = row
            .try_get("", "id")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let grade_item_id: String = row
            .try_get("", "grade_item_id")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let student_id_str: String = row
            .try_get("", "student_id")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let score: Option<f64> = row
            .try_get("", "score")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let is_auto_populated: bool = row
            .try_get("", "is_auto_populated")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let override_score: Option<f64> = row
            .try_get("", "override_score")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let created_at: String = row
            .try_get("", "created_at")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let updated_at: String = row
            .try_get("", "updated_at")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
        let deleted_at: Option<String> = row
            .try_get("", "deleted_at")
            .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;

        scores.push(grade_scores::Model {
            id: Uuid::parse_str(&id)
                .map_err(|e| AppError::InternalServerError(format!("UUID parse error: {}", e)))?,
            grade_item_id: Uuid::parse_str(&grade_item_id)
                .map_err(|e| AppError::InternalServerError(format!("UUID parse error: {}", e)))?,
            student_id: Uuid::parse_str(&student_id_str)
                .map_err(|e| AppError::InternalServerError(format!("UUID parse error: {}", e)))?,
            score,
            is_auto_populated,
            override_score,
            created_at: chrono::NaiveDateTime::parse_from_str(&created_at, "%Y-%m-%d %H:%M:%S%.f")
                .or_else(|_| {
                    chrono::NaiveDateTime::parse_from_str(&created_at, "%Y-%m-%dT%H:%M:%S%.f")
                })
                .map_err(|e| {
                    AppError::InternalServerError(format!("DateTime parse error: {}", e))
                })?,
            updated_at: chrono::NaiveDateTime::parse_from_str(&updated_at, "%Y-%m-%d %H:%M:%S%.f")
                .or_else(|_| {
                    chrono::NaiveDateTime::parse_from_str(&updated_at, "%Y-%m-%dT%H:%M:%S%.f")
                })
                .map_err(|e| {
                    AppError::InternalServerError(format!("DateTime parse error: {}", e))
                })?,
            deleted_at: deleted_at
                .map(|dt| {
                    chrono::NaiveDateTime::parse_from_str(&dt, "%Y-%m-%d %H:%M:%S%.f").or_else(
                        |_| chrono::NaiveDateTime::parse_from_str(&dt, "%Y-%m-%dT%H:%M:%S%.f"),
                    )
                })
                .transpose()
                .map_err(|e| {
                    AppError::InternalServerError(format!("DateTime parse error: {}", e))
                })?,
        });
    }

    Ok(scores)
}
