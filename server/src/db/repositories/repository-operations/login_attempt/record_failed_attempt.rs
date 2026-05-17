use chrono::Duration;
use sea_orm::*;

use ::entity::login_attempts;
use crate::utils::{AppError, AppResult};
use super::record_attempt::record_attempt;

/// Record a failed attempt with progressive lockout
/// Returns (attempts_remaining, locked_until, lockout_level)
pub async fn record_failed_attempt(
    db: &DatabaseConnection,
    username: &str,
    ip: &str,
) -> AppResult<(i32, Option<chrono::NaiveDateTime>, Option<i32>)> {
    let device_id = format!("{}-{}", username, ip);
    record_attempt(db, None, false, Some(device_id.clone())).await?;

    let thirty_min_ago = chrono::Utc::now().naive_utc() - Duration::minutes(30);
    let recent_attempts = login_attempts::Entity::find()
        .filter(login_attempts::Column::DeviceId.eq(&device_id))
        .filter(login_attempts::Column::Success.eq(false))
        .filter(login_attempts::Column::AttemptedAt.gt(thirty_min_ago))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let attempt_count = recent_attempts.len() as i32;
    let max_attempts_per_cycle = 5;

    let total_failed_attempts = attempt_count;
    let lockout_level = (total_failed_attempts / max_attempts_per_cycle).min(5);

    let lockout_duration = match lockout_level {
        0 => None,
        1 => Some(Duration::minutes(5)),
        2 => Some(Duration::minutes(15)),
        3 => Some(Duration::minutes(30)),
        4 => Some(Duration::minutes(60)),
        5 => Some(Duration::minutes(120)),
        _ => Some(Duration::minutes(120)),
    };

    let attempts_in_current_cycle = (total_failed_attempts % max_attempts_per_cycle) + 1;

    if attempts_in_current_cycle > max_attempts_per_cycle {
        if let Some(duration) = lockout_duration {
            let locked_until = chrono::Utc::now().naive_utc() + duration;
            Ok((0, Some(locked_until), Some(lockout_level)))
        } else {
            Ok((0, None, Some(lockout_level)))
        }
    } else {
        let attempts_remaining = max_attempts_per_cycle - attempts_in_current_cycle + 1;
        Ok((attempts_remaining, None, Some(lockout_level)))
    }
}
