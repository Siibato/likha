use chrono::{Duration, Utc};
use sea_orm::*;
use uuid::Uuid;

use ::entity::login_attempts;
use crate::utils::{AppError, AppResult};

pub struct LoginAttemptRepository {
    db: DatabaseConnection,
}

impl LoginAttemptRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Record a login attempt (successful or failed)
    /// Returns (success, is_new_record)
    pub async fn record_attempt(
        &self,
        user_id: Option<Uuid>,
        success: bool,
        device_id: Option<String>,
    ) -> AppResult<()> {
        let now = Utc::now().naive_utc();
        let record = login_attempts::ActiveModel {
            id: Set(Uuid::new_v4()),
            user_id: Set(user_id),
            attempted_at: Set(now),
            success: Set(success),
            device_id: Set(device_id),
        };

        record.insert(&self.db).await.map_err(|e| {
            AppError::InternalServerError(format!("Failed to create login attempt record: {}", e))
        })?;

        Ok(())
    }

    /// Record a failed attempt - kept for backward compatibility with auth service
    /// This is a simplified version that just logs the attempt
    pub async fn record_failed_attempt(
        &self,
        _username: &str,
        ip: &str,
    ) -> AppResult<(i32, Option<chrono::NaiveDateTime>)> {
        // Create a deterministic device_id from IP for tracking
        let device_id = format!("ip-{}", ip);
        self.record_attempt(None, false, Some(device_id)).await?;

        // Count recent failed attempts from this IP in the last 5 minutes
        let five_min_ago = Utc::now().naive_utc() - Duration::minutes(5);
        let recent_attempts = login_attempts::Entity::find()
            .filter(login_attempts::Column::DeviceId.eq(format!("ip-{}", ip)))
            .filter(login_attempts::Column::Success.eq(false))
            .filter(login_attempts::Column::AttemptedAt.gt(five_min_ago))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let attempt_count = recent_attempts.len() as i32;

        // If 5+ failed attempts in 5 minutes, return locked status
        if attempt_count >= 5 {
            let locked_until = Utc::now().naive_utc() + Duration::minutes(5);
            Ok((5, Some(locked_until)))
        } else {
            Ok((attempt_count + 1, None))
        }
    }

    /// Check if user is locked out - kept for backward compatibility
    pub async fn check_lockout(
        &self,
        _username: &str,
        ip: &str,
    ) -> AppResult<(bool, i64)> {
        let device_id = format!("ip-{}", ip);
        let five_min_ago = Utc::now().naive_utc() - Duration::minutes(5);

        let recent_failures = login_attempts::Entity::find()
            .filter(login_attempts::Column::DeviceId.eq(device_id))
            .filter(login_attempts::Column::Success.eq(false))
            .filter(login_attempts::Column::AttemptedAt.gt(five_min_ago))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if recent_failures.len() >= 5 {
            // Locked for 5 minutes from last attempt
            if let Some(last_attempt) = recent_failures.last() {
                let locked_until = last_attempt.attempted_at + Duration::minutes(5);
                let now = Utc::now().naive_utc();
                if locked_until > now {
                    let remaining = (locked_until - now).num_seconds();
                    return Ok((true, remaining));
                }
            }
        }

        Ok((false, 0))
    }

    /// Clear attempts - kept for backward compatibility
    pub async fn clear_attempts(&self, _username: &str, _ip: &str) -> AppResult<()> {
        // In new schema, we don't delete attempts (they're audit records)
        // This is a no-op to maintain API compatibility
        Ok(())
    }

    pub async fn clear_all_attempts(&self) -> AppResult<()> {
        // Delete old attempts (keep only last 30 days for audit trail)
        let thirty_days_ago = Utc::now().naive_utc() - Duration::days(30);
        login_attempts::Entity::delete_many()
            .filter(login_attempts::Column::AttemptedAt.lt(thirty_days_ago))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear old attempts: {}", e)))?;
        Ok(())
    }
}
