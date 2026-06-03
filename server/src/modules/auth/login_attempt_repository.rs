use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::db::repositories::repository_operations::login_attempt as ops;
use crate::utils::AppResult;

pub struct LoginAttemptRepository {
    db: DatabaseConnection,
}

impl LoginAttemptRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Record a login attempt (successful or failed)
    pub async fn record_attempt(
        &self,
        user_id: Option<Uuid>,
        success: bool,
        device_id: Option<String>,
    ) -> AppResult<()> {
        ops::record_attempt(&self.db, user_id, success, device_id).await
    }

    /// Record a failed attempt with progressive lockout
    pub async fn record_failed_attempt(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(i32, Option<chrono::NaiveDateTime>, Option<i32>)> {
        ops::record_failed_attempt(&self.db, username, ip).await
    }

    /// Check if user is locked out with progressive lockout
    pub async fn check_lockout(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(bool, i64, Option<i32>)> {
        ops::check_lockout(&self.db, username, ip).await
    }

    /// Clear failed attempts for a specific username/IP combination on successful login
    pub async fn clear_attempts(&self, username: &str, ip: &str) -> AppResult<()> {
        ops::clear_attempts(&self.db, username, ip).await
    }

    pub async fn clear_all_attempts(&self) -> AppResult<()> {
        ops::clear_all_attempts(&self.db).await
    }
}
