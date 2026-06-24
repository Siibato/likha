use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use super::get_learner_details::get_learner_details;
use crate::utils::{AppError, AppResult};
use ::entity::learner_details;

pub async fn upsert_learner_details(
    db: &DatabaseConnection,
    user_id: Uuid,
    lrn: Option<String>,
    sex: Option<String>,
    track_strand: Option<String>,
    curriculum: Option<String>,
    birthdate: Option<chrono::NaiveDate>,
    birthplace: Option<String>,
    home_address: Option<String>,
    father_name: Option<String>,
    father_contact: Option<String>,
    mother_name: Option<String>,
    mother_contact: Option<String>,
    guardian_name: Option<String>,
    guardian_contact: Option<String>,
    date_admitted: Option<chrono::NaiveDate>,
) -> AppResult<learner_details::Model> {
    let now = Utc::now().naive_utc();

    if let Some(existing) = get_learner_details(db, user_id).await? {
        let mut am: learner_details::ActiveModel = existing.into();
        am.lrn = sea_orm::ActiveValue::Set(lrn);
        am.sex = sea_orm::ActiveValue::Set(sex);
        am.track_strand = sea_orm::ActiveValue::Set(track_strand);
        am.curriculum = sea_orm::ActiveValue::Set(curriculum);
        am.birthdate = sea_orm::ActiveValue::Set(birthdate);
        am.birthplace = sea_orm::ActiveValue::Set(birthplace);
        am.home_address = sea_orm::ActiveValue::Set(home_address);
        am.father_name = sea_orm::ActiveValue::Set(father_name);
        am.father_contact = sea_orm::ActiveValue::Set(father_contact);
        am.mother_name = sea_orm::ActiveValue::Set(mother_name);
        am.mother_contact = sea_orm::ActiveValue::Set(mother_contact);
        am.guardian_name = sea_orm::ActiveValue::Set(guardian_name);
        am.guardian_contact = sea_orm::ActiveValue::Set(guardian_contact);
        am.date_admitted = sea_orm::ActiveValue::Set(date_admitted);
        am.updated_at = sea_orm::ActiveValue::Set(now);
        am.update(db).await.map_err(|e| {
            AppError::InternalServerError(format!("Failed to update learner details: {}", e))
        })
    } else {
        let am = learner_details::ActiveModel {
            id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
            user_id: sea_orm::ActiveValue::Set(user_id),
            lrn: sea_orm::ActiveValue::Set(lrn),
            sex: sea_orm::ActiveValue::Set(sex),
            track_strand: sea_orm::ActiveValue::Set(track_strand),
            curriculum: sea_orm::ActiveValue::Set(curriculum),
            birthdate: sea_orm::ActiveValue::Set(birthdate),
            birthplace: sea_orm::ActiveValue::Set(birthplace),
            home_address: sea_orm::ActiveValue::Set(home_address),
            father_name: sea_orm::ActiveValue::Set(father_name),
            father_contact: sea_orm::ActiveValue::Set(father_contact),
            mother_name: sea_orm::ActiveValue::Set(mother_name),
            mother_contact: sea_orm::ActiveValue::Set(mother_contact),
            guardian_name: sea_orm::ActiveValue::Set(guardian_name),
            guardian_contact: sea_orm::ActiveValue::Set(guardian_contact),
            date_admitted: sea_orm::ActiveValue::Set(date_admitted),
            created_at: sea_orm::ActiveValue::Set(now),
            updated_at: sea_orm::ActiveValue::Set(now),
            deleted_at: sea_orm::ActiveValue::Set(None),
        };
        am.insert(db).await.map_err(|e| {
            AppError::InternalServerError(format!("Failed to insert learner details: {}", e))
        })
    }
}
