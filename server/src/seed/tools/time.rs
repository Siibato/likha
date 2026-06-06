use chrono::{Duration, NaiveDateTime, Utc};

#[derive(Debug, Clone, Copy)]
pub struct SeedContext {
    now: NaiveDateTime,
}

impl SeedContext {
    pub fn new() -> Self {
        Self {
            now: Utc::now().naive_utc(),
        }
    }

    pub fn at(now: NaiveDateTime) -> Self {
        Self { now }
    }

    pub fn now(&self) -> NaiveDateTime {
        self.now
    }

    pub fn days_ago(&self, n: i64) -> NaiveDateTime {
        self.now - Duration::days(n)
    }

    pub fn days_from_now(&self, n: i64) -> NaiveDateTime {
        self.now + Duration::days(n)
    }
}

impl Default for SeedContext {
    fn default() -> Self {
        Self::new()
    }
}
