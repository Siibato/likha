use chrono::{NaiveDateTime, Utc};
use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::utils::AppResult;
use super::find_by_teacher_id::find_by_teacher_id;

pub async fn get_metadata(db: &DatabaseConnection, teacher_id: Uuid) -> AppResult<(NaiveDateTime, usize, String)> {
    let classes = find_by_teacher_id(db, teacher_id).await?;
    let count = classes.len();

    let last_modified = if count > 0 {
        classes.iter().map(|c| c.updated_at).max().unwrap_or_else(|| Utc::now().naive_utc())
    } else {
        Utc::now().naive_utc()
    };

    let etag_data = format!("{}-{}", count, last_modified);
    let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

    Ok((last_modified, count, etag))
}
