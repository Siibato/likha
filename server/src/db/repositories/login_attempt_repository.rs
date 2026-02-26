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

    async fn find(&self, username: &str, ip: &str) -> AppResult<Option<login_attempts::Model>> {
        login_attempts::Entity::find()
            .filter(login_attempts::Column::Username.eq(username))
            .filter(login_attempts::Column::IpAddress.eq(ip))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn record_failed_attempt(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(i32, Option<chrono::NaiveDateTime>)> {
        let now = Utc::now().naive_utc();

        if let Some(record) = self.find(username, ip).await? {
            // Check if lockout has expired
            if let Some(locked_until) = record.locked_until {
                if locked_until <= now {
                    // Lockout expired, reset the attempt
                    let mut active: login_attempts::ActiveModel = record.into();
                    active.attempt_count = Set(1);
                    active.locked_until = Set(None);
                    active.first_attempt_at = Set(now);
                    active.last_attempt_at = Set(now);
                    active.update(&self.db).await.map_err(|e| {
                        AppError::InternalServerError(format!("Failed to update login attempt: {}", e))
                    })?;
                    return Ok((1, None));
                } else {
                    // Still locked
                    return Ok((5, Some(locked_until)));
                }
            }

            // Increment attempt count
            let new_count = record.attempt_count + 1;
            let new_locked_until = if new_count >= 5 {
                Some(now + Duration::minutes(5))
            } else {
                None
            };

            let mut active: login_attempts::ActiveModel = record.into();
            active.attempt_count = Set(new_count);
            active.locked_until = Set(new_locked_until);
            active.last_attempt_at = Set(now);
            active.update(&self.db).await.map_err(|e| {
                AppError::InternalServerError(format!("Failed to update login attempt: {}", e))
            })?;

            Ok((new_count, new_locked_until))
        } else {
            // Create new record
            let record = login_attempts::ActiveModel {
                id: Set(Uuid::new_v4()),
                username: Set(username.to_string()),
                ip_address: Set(ip.to_string()),
                attempt_count: Set(1),
                first_attempt_at: Set(now),
                last_attempt_at: Set(now),
                locked_until: Set(None),
            };

            record.insert(&self.db).await.map_err(|e| {
                AppError::InternalServerError(format!("Failed to create login attempt record: {}", e))
            })?;

            Ok((1, None))
        }
    }

    pub async fn check_lockout(
        &self,
        username: &str,
        ip: &str,
    ) -> AppResult<(bool, i64)> {
        if let Some(record) = self.find(username, ip).await? {
            if let Some(locked_until) = record.locked_until {
                let now = Utc::now().naive_utc();
                if locked_until > now {
                    // Still locked
                    let remaining = (locked_until - now).num_seconds();
                    return Ok((true, remaining));
                } else {
                    // Lockout has expired, clear it
                    let mut active: login_attempts::ActiveModel = record.into();
                    active.locked_until = Set(None);
                    active.attempt_count = Set(0);
                    active.update(&self.db).await.map_err(|e| {
                        AppError::InternalServerError(format!("Failed to update login attempt: {}", e))
                    })?;
                }
            }
        }
        Ok((false, 0))
    }

    pub async fn clear_attempts(&self, username: &str, ip: &str) -> AppResult<()> {
        login_attempts::Entity::delete_many()
            .filter(login_attempts::Column::Username.eq(username))
            .filter(login_attempts::Column::IpAddress.eq(ip))
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear attempts: {}", e)))?;
        Ok(())
    }

    pub async fn clear_all_attempts(&self) -> AppResult<()> {
        login_attempts::Entity::delete_many()
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear all attempts: {}", e)))?;
        Ok(())
    }
}
