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

    /// Record a failed attempt with progressive lockout
    pub async fn record_failed_attempt(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(i32, Option<chrono::NaiveDateTime>, Option<i32>)> {
        // Create a deterministic device_id from username+IP for better tracking
        let device_id = format!("{}-{}", username, ip);
        self.record_attempt(None, false, Some(device_id.clone())).await?;

        // Count recent failed attempts from this username+IP combination in the last 30 minutes
        let thirty_min_ago = Utc::now().naive_utc() - Duration::minutes(30);
        let recent_attempts = login_attempts::Entity::find()
            .filter(login_attempts::Column::DeviceId.eq(&device_id))
            .filter(login_attempts::Column::Success.eq(false))
            .filter(login_attempts::Column::AttemptedAt.gt(thirty_min_ago))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let attempt_count = recent_attempts.len() as i32;
        let max_attempts_per_cycle = 5;

        // Calculate which lockout level we're at based on total failed attempts
        let total_failed_attempts = attempt_count;
        let lockout_level = (total_failed_attempts / max_attempts_per_cycle).min(5);

        // Progressive lockout durations (5min, 15min, 30min, 1hr, 2hr)
        let lockout_duration = match lockout_level {
            0 => None,                                    // No lockout
            1 => Some(Duration::minutes(5)),             // 5 minutes
            2 => Some(Duration::minutes(15)),            // 15 minutes  
            3 => Some(Duration::minutes(30)),            // 30 minutes
            4 => Some(Duration::minutes(60)),            // 1 hour
            5 => Some(Duration::minutes(120)),           // 2 hours
            _ => Some(Duration::minutes(120)),           // Max 2 hours
        };

        let attempts_in_current_cycle = (total_failed_attempts % max_attempts_per_cycle) + 1;

        if attempts_in_current_cycle > max_attempts_per_cycle {
            // We've hit the threshold for this cycle, apply lockout
            if let Some(duration) = lockout_duration {
                let locked_until = Utc::now().naive_utc() + duration;
                Ok((0, Some(locked_until), Some(lockout_level)))
            } else {
                Ok((0, None, Some(lockout_level)))
            }
        } else {
            // Still have attempts remaining in current cycle
            let attempts_remaining = max_attempts_per_cycle - attempts_in_current_cycle + 1;
            Ok((attempts_remaining, None, Some(lockout_level)))
        }
    }

    /// Check if user is locked out with progressive lockout
    pub async fn check_lockout(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(bool, i64, Option<i32>)> {
        let device_id = format!("{}-{}", username, ip);
        let thirty_min_ago = Utc::now().naive_utc() - Duration::minutes(30);

        let recent_failures = login_attempts::Entity::find()
            .filter(login_attempts::Column::DeviceId.eq(&device_id))
            .filter(login_attempts::Column::Success.eq(false))
            .filter(login_attempts::Column::AttemptedAt.gt(thirty_min_ago))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let attempt_count = recent_failures.len() as i32;
        let max_attempts_per_cycle = 5;
        
        // Calculate lockout level
        let lockout_level = (attempt_count / max_attempts_per_cycle).min(5);
        
        // Check if we're in a lockout period
        if attempt_count >= max_attempts_per_cycle {
            if let Some(last_attempt) = recent_failures.last() {
                let attempts_in_cycle = attempt_count % max_attempts_per_cycle;
                
                // Progressive lockout durations
                let lockout_duration = match lockout_level {
                    0 => Duration::minutes(0),
                    1 => Duration::minutes(5),      // 5 minutes
                    2 => Duration::minutes(15),     // 15 minutes  
                    3 => Duration::minutes(30),     // 30 minutes
                    4 => Duration::minutes(60),     // 1 hour
                    5 => Duration::minutes(120),    // 2 hours
                    _ => Duration::minutes(120),    // Max 2 hours
                };
                
                let locked_until = last_attempt.attempted_at + lockout_duration;
                let now = Utc::now().naive_utc();
                
                if locked_until > now && attempts_in_cycle == 0 {
                    let remaining = (locked_until - now).num_seconds();
                    return Ok((true, remaining, Some(lockout_level)));
                }
            }
        }

        Ok((false, 0, Some(lockout_level)))
    }

    /// Clear failed attempts for a specific username/IP combination on successful login
    pub async fn clear_attempts(&self, username: &str, ip: &str) -> AppResult<()> {
        let device_id = format!("{}-{}", username, ip);
        
        // Delete only failed attempts for this device_id (keep successful attempts for audit)
        login_attempts::Entity::delete_many()
            .filter(login_attempts::Column::DeviceId.eq(&device_id))
            .filter(login_attempts::Column::Success.eq(false))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear attempts: {}", e)))?;
        
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
