use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};

pub async fn soft_delete_submissions_by_assessment(
    db: &DatabaseConnection,
    assessment_id: Uuid,
) -> AppResult<()> {
    use chrono::Utc;
    let now = Utc::now().naive_utc();
    let assessment_id_str = assessment_id.to_string();
    let now_str = now.to_string();

    let query = format!(
        "UPDATE assessment_submissions SET deleted_at = '{}', updated_at = '{}' WHERE assessment_id = '{}' AND deleted_at IS NULL",
        now_str, now_str, assessment_id_str
    );

    db.execute(Statement::from_string(DbBackend::Sqlite, query))
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to delete submissions: {}", e))
        })?;

    Ok(())
}
