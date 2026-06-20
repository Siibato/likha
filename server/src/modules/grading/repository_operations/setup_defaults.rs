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
    let num_terms = crate::modules::grading::helpers::term_count::term_count("term") as i32;
    for term in 1..=num_terms {
        let config = upsert_config(db, class_id, term, preset.ww, preset.pt, preset.qa).await?;
        configs.push(config);
    }

    Ok(configs)
}
