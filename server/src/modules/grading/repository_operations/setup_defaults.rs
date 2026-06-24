use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::upsert_config::upsert_config;
use crate::utils::{AppError, AppResult};
use ::entity::grade_record;

pub async fn setup_defaults(
    db: &DatabaseConnection,
    class_id: Uuid,
    subject_group: &str,
    ww_weight: Option<f64>,
    pt_weight: Option<f64>,
    qa_weight: Option<f64>,
) -> AppResult<Vec<grade_record::Model>> {
    let (ww, pt, qa) = match (ww_weight, pt_weight, qa_weight) {
        (Some(ww), Some(pt), Some(qa)) => (ww, pt, qa),
        _ => {
            let preset = crate::modules::grading::helpers::deped_weights::get_preset(subject_group)
                .ok_or_else(|| {
                    AppError::BadRequest(format!(
                        "Unknown subject group '{}'. No DepEd preset found.",
                        subject_group
                    ))
                })?;
            (preset.ww, preset.pt, preset.qa)
        }
    };

    let mut configs = Vec::new();
    let num_terms = crate::modules::grading::helpers::term_count::term_count("term") as i32;
    for term in 1..=num_terms {
        let config = upsert_config(db, class_id, term, ww, pt, qa).await?;
        configs.push(config);
    }

    Ok(configs)
}
