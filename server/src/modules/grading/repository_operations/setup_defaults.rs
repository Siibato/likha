use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::grade_record;
use crate::utils::{AppError, AppResult};
use super::upsert_config::upsert_config;

pub async fn setup_defaults(
    db: &DatabaseConnection,
    class_id: Uuid,
    subject_group: &str,
) -> AppResult<Vec<grade_record::Model>> {
    let preset = crate::modules::grading::helpers::deped_weights::get_preset(subject_group)
        .ok_or_else(|| {
            AppError::BadRequest(format!(
                "Unknown subject group '{}'. No DepEd preset found.",
                subject_group
            ))
        })?;

    let mut configs = Vec::new();
    for period in 1..=4 {
        let config = upsert_config(db, class_id, period, preset.ww, preset.pt, preset.qa).await?;
        configs.push(config);
    }

    Ok(configs)
}
