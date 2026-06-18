use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};
use chrono::Utc;

use crate::seed::specs::LearnerDetailsSpec;
use crate::utils::AppError;
use ::entity::learner_details;

pub async fn insert_learner_details(
    db: &DatabaseConnection,
    specs: &[LearnerDetailsSpec],
) -> Result<(), AppError> {
    let now = Utc::now().naive_utc();

    for spec in specs {
        let am = learner_details::ActiveModel {
            id: Set(spec.id),
            user_id: Set(spec.user_id),
            lrn: Set(spec.lrn.clone()),
            age: Set(spec.age),
            sex: Set(spec.sex.clone()),
            track_strand: Set(spec.track_strand.clone()),
            curriculum: Set(spec.curriculum.clone()),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
