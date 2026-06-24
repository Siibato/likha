use crate::utils::error::{AppError, AppResult};
use chrono::{Datelike, NaiveDate, NaiveDateTime, Utc};

pub fn parse_datetime(s: &str) -> AppResult<NaiveDateTime> {
    NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S")
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S"))
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f"))
        .map_err(|_| {
            AppError::BadRequest(format!(
                "Invalid datetime format: {}. Use YYYY-MM-DDTHH:MM:SS",
                s
            ))
        })
}

pub fn fmt_utc(dt: NaiveDateTime) -> String {
    dt.format("%Y-%m-%dT%H:%M:%SZ").to_string()
}

pub fn calculate_age_at(birthdate: &NaiveDate, reference: NaiveDate) -> i32 {
    let mut age = reference.year() - birthdate.year();

    let birthday_has_not_happened = reference.month() < birthdate.month()
        || (reference.month() == birthdate.month() && reference.day() < birthdate.day());
    if birthday_has_not_happened {
        age -= 1;
    }

    age.max(0)
}

pub fn calculate_current_age(birthdate: Option<NaiveDate>) -> Option<i32> {
    birthdate.map(|bd| {
        let today = Utc::now().date_naive();
        calculate_age_at(&bd, today)
    })
}
