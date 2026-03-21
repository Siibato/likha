use chrono::NaiveDateTime;
use crate::utils::error::{AppError, AppResult};

pub fn parse_datetime(s: &str) -> AppResult<NaiveDateTime> {
    NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S")
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S"))
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f"))
        .map_err(|_| AppError::BadRequest(format!(
            "Invalid datetime format: {}. Use YYYY-MM-DDTHH:MM:SS", s
        )))
}

pub fn fmt_utc(dt: NaiveDateTime) -> String {
    dt.format("%Y-%m-%dT%H:%M:%SZ").to_string()
}
