use sea_orm::DatabaseConnection;

use crate::modules::setup::repository_operations as ops;
use crate::utils::AppResult;

pub async fn seed_settings(db: &DatabaseConnection, default_code: &str) -> AppResult<()> {
    let existing = ops::get_settings(db).await;
    if existing.is_err() {
        ops::insert_settings(db, default_code.to_string()).await?;
    }
    Ok(())
}
