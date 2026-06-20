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
            birthdate: Set(spec.birthdate),
            birthplace: Set(spec.birthplace.clone()),
            home_address: Set(spec.home_address.clone()),
            father_name: Set(spec.father_name.clone()),
            father_contact: Set(spec.father_contact.clone()),
            mother_name: Set(spec.mother_name.clone()),
            mother_contact: Set(spec.mother_contact.clone()),
            guardian_name: Set(spec.guardian_name.clone()),
            guardian_contact: Set(spec.guardian_contact.clone()),
            date_admitted: Set(spec.date_admitted),
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
