use chrono::Duration;
use sea_orm::*;

use ::entity::login_attempts;
use crate::utils::{AppError, AppResult};

pub async fn check_lockout(
    db: &DatabaseConnection,
    username: &str,
    ip: &str,
) -> AppResult<(bool, i64, Option<i32>)> {
    let device_id = format!("{}-{}", username, ip);
    let thirty_min_ago = chrono::Utc::now().naive_utc() - Duration::minutes(30);

    let recent_failures = login_attempts::Entity::find()
        .filter(login_attempts::Column::DeviceId.eq(&device_id))
        .filter(login_attempts::Column::Success.eq(false))
        .filter(login_attempts::Column::AttemptedAt.gt(thirty_min_ago))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let attempt_count = recent_failures.len() as i32;
    let max_attempts_per_cycle = 5;

    let lockout_level = (attempt_count / max_attempts_per_cycle).min(5);

    if attempt_count >= max_attempts_per_cycle {
        if let Some(last_attempt) = recent_failures.last() {
            let attempts_in_cycle = attempt_count % max_attempts_per_cycle;

            let lockout_duration = match lockout_level {
                0 => Duration::minutes(0),
                1 => Duration::minutes(5),
                2 => Duration::minutes(15),
                3 => Duration::minutes(30),
                4 => Duration::minutes(60),
                5 => Duration::minutes(120),
                _ => Duration::minutes(120),
            };

            let locked_until = last_attempt.attempted_at + lockout_duration;
            let now = chrono::Utc::now().naive_utc();

            if locked_until > now && attempts_in_cycle == 0 {
                let remaining = (locked_until - now).num_seconds();
                return Ok((true, remaining, Some(lockout_level)));
            }
        }
    }

    Ok((false, 0, Some(lockout_level)))
}
