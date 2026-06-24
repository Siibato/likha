use chrono::Utc;
use sea_orm::{ActiveModelTrait, DatabaseConnection};
use uuid::Uuid;

use super::get_account_details::get_teacher_details;
use crate::modules::admin::schema::{LearnerDetailsPayload, TeacherDetailsPayload};
use crate::modules::student_records::repository_operations::upsert_learner_details::upsert_learner_details;
use crate::utils::validators::Validator;
use crate::utils::{AppError, AppResult};
use ::entity::teacher_details;

pub async fn upsert_account_details(
    db: &DatabaseConnection,
    user_id: Uuid,
    role: &str,
    learner_payload: Option<LearnerDetailsPayload>,
    teacher_payload: Option<TeacherDetailsPayload>,
) -> AppResult<()> {
    match role {
        "student" => {
            if let Some(p) = learner_payload {
                let normalized_sex = Validator::normalize_optional_sex(p.sex)?;
                upsert_learner_details(
                    db,
                    user_id,
                    p.lrn,
                    normalized_sex,
                    p.track_strand,
                    p.curriculum,
                    p.birthdate.and_then(|s| s.parse().ok()),
                    p.birthplace,
                    p.home_address,
                    p.father_name,
                    p.father_contact,
                    p.mother_name,
                    p.mother_contact,
                    p.guardian_name,
                    p.guardian_contact,
                    p.date_admitted.and_then(|s| s.parse().ok()),
                )
                .await?;
            }
        }
        "teacher" => {
            if let Some(p) = teacher_payload {
                let normalized_sex = Validator::normalize_optional_sex(p.sex)?;
                upsert_teacher_details(
                    db,
                    user_id,
                    p.license_id,
                    p.rank,
                    p.position,
                    normalized_sex,
                    p.birthdate.and_then(|s| s.parse().ok()),
                    p.home_address,
                    p.date_hired.and_then(|s| s.parse().ok()),
                    p.education_level,
                    p.specialization,
                    p.contact_number,
                )
                .await?;
            }
        }
        _ => {}
    }
    Ok(())
}

pub async fn upsert_teacher_details(
    db: &DatabaseConnection,
    user_id: Uuid,
    license_id: Option<String>,
    rank: Option<String>,
    position: Option<String>,
    sex: Option<String>,
    birthdate: Option<chrono::NaiveDate>,
    home_address: Option<String>,
    date_hired: Option<chrono::NaiveDate>,
    education_level: Option<String>,
    specialization: Option<String>,
    contact_number: Option<String>,
) -> AppResult<teacher_details::Model> {
    let now = Utc::now().naive_utc();

    if let Some(existing) = get_teacher_details(db, user_id).await? {
        let mut am: teacher_details::ActiveModel = existing.into();
        am.license_id = sea_orm::ActiveValue::Set(license_id);
        am.rank = sea_orm::ActiveValue::Set(rank);
        am.position = sea_orm::ActiveValue::Set(position);
        am.sex = sea_orm::ActiveValue::Set(sex);
        am.birthdate = sea_orm::ActiveValue::Set(birthdate);
        am.home_address = sea_orm::ActiveValue::Set(home_address);
        am.date_hired = sea_orm::ActiveValue::Set(date_hired);
        am.education_level = sea_orm::ActiveValue::Set(education_level);
        am.specialization = sea_orm::ActiveValue::Set(specialization);
        am.contact_number = sea_orm::ActiveValue::Set(contact_number);
        am.updated_at = sea_orm::ActiveValue::Set(now);
        am.update(db).await.map_err(|e| {
            AppError::InternalServerError(format!("Failed to update teacher details: {}", e))
        })
    } else {
        let am = teacher_details::ActiveModel {
            id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
            user_id: sea_orm::ActiveValue::Set(user_id),
            license_id: sea_orm::ActiveValue::Set(license_id),
            rank: sea_orm::ActiveValue::Set(rank),
            position: sea_orm::ActiveValue::Set(position),
            sex: sea_orm::ActiveValue::Set(sex),
            birthdate: sea_orm::ActiveValue::Set(birthdate),
            home_address: sea_orm::ActiveValue::Set(home_address),
            date_hired: sea_orm::ActiveValue::Set(date_hired),
            education_level: sea_orm::ActiveValue::Set(education_level),
            specialization: sea_orm::ActiveValue::Set(specialization),
            contact_number: sea_orm::ActiveValue::Set(contact_number),
            created_at: sea_orm::ActiveValue::Set(now),
            updated_at: sea_orm::ActiveValue::Set(now),
            deleted_at: sea_orm::ActiveValue::Set(None),
        };
        am.insert(db).await.map_err(|e| {
            AppError::InternalServerError(format!("Failed to insert teacher details: {}", e))
        })
    }
}
