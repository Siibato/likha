use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::term_grades;
use crate::utils::{AppError, AppResult};
use super::get_term_grade::get_term_grade;

pub async fn upsert_term_grade(
    db: &DatabaseConnection,
    class_id: Uuid,
    student_id: Uuid,
    term_number: i32,
    initial_grade: f64,
    transmuted_grade: i32,
    is_locked: bool,
) -> AppResult<term_grades::Model> {
    let now = Utc::now().naive_utc();
    let id = Uuid::new_v4();

    let sql = r#"
        INSERT INTO term_grades (id, class_id, student_id, term_number,
            initial_grade, transmuted_grade, is_locked,
            created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(class_id, student_id, term_number) DO UPDATE SET
            initial_grade = excluded.initial_grade,
            transmuted_grade = excluded.transmuted_grade,
            is_locked = excluded.is_locked,
            updated_at = excluded.updated_at
    "#;

    let stmt = Statement::from_sql_and_values(
        DbBackend::Sqlite,
        sql,
        vec![
            id.to_string().into(),
            class_id.to_string().into(),
            student_id.to_string().into(),
            term_number.into(),
            initial_grade.into(),
            transmuted_grade.into(),
            is_locked.into(),
            now.to_string().into(),
            now.to_string().into(),
        ],
    );

    db.execute(stmt)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to upsert period grade: {}", e)))?;

    get_term_grade(db, class_id, student_id, term_number)
        .await?
        .ok_or_else(|| AppError::InternalServerError("Period grade not found after upsert".to_string()))
}
