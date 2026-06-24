use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use super::get_config::get_config;
use crate::utils::{AppError, AppResult};
use ::entity::grade_record;

pub async fn upsert_config(
    db: &DatabaseConnection,
    class_id: Uuid,
    term_number: i32,
    ww_weight: f64,
    pt_weight: f64,
    qa_weight: f64,
) -> AppResult<grade_record::Model> {
    let now = Utc::now().naive_utc();
    let id = Uuid::new_v4();

    let sql = r#"
        INSERT INTO grade_record (id, class_id, term_number, ww_weight, pt_weight, qa_weight, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(class_id, term_number) DO UPDATE SET
            ww_weight = excluded.ww_weight,
            pt_weight = excluded.pt_weight,
            qa_weight = excluded.qa_weight,
            updated_at = excluded.updated_at
    "#;

    let stmt = Statement::from_sql_and_values(
        DbBackend::Sqlite,
        sql,
        vec![
            id.into(),
            class_id.into(),
            term_number.into(),
            ww_weight.into(),
            pt_weight.into(),
            qa_weight.into(),
            now.into(),
            now.into(),
        ],
    );

    db.execute(stmt)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to upsert config: {}", e)))?;

    get_config(db, class_id, term_number)
        .await?
        .ok_or_else(|| AppError::InternalServerError("Config not found after upsert".to_string()))
}
