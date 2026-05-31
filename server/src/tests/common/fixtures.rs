use chrono::Utc;
use uuid::Uuid;

pub fn new_id() -> Uuid {
    Uuid::new_v4()
}

pub fn iso_now() -> String {
    Utc::now().to_rfc3339()
}
