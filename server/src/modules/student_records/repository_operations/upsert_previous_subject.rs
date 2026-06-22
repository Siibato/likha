use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::previous_school_subjects;
use ::entity::previous_school_term_grades;
use crate::utils::{AppError, AppResult};

pub async fn upsert_previous_subject(
    db: &DatabaseConnection,
    student_id: Uuid,
    school_history_id: Uuid,
    subject_name: String,
    subject_group: Option<String>,
    term_type: String,
    term_grades: Vec<Option<i32>>,
    final_grade: Option<i32>,
    descriptor: Option<String>,
) -> AppResult<previous_school_subjects::Model> {
    let now = Utc::now().naive_utc();

    let existing = previous_school_subjects::Entity::find()
        .filter(previous_school_subjects::Column::StudentId.eq(student_id))
        .filter(previous_school_subjects::Column::SchoolHistoryId.eq(school_history_id))
        .filter(previous_school_subjects::Column::SubjectName.eq(&subject_name))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let subject_model = if let Some(model) = existing {
        let mut am: previous_school_subjects::ActiveModel = model.into();
        am.subject_group = sea_orm::ActiveValue::Set(subject_group);
        am.term_type = sea_orm::ActiveValue::Set(term_type);
        am.final_grade = sea_orm::ActiveValue::Set(final_grade);
        am.descriptor = sea_orm::ActiveValue::Set(descriptor);
        am.updated_at = sea_orm::ActiveValue::Set(now);
        am.update(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update subject: {}", e)))?
    } else {
        let am = previous_school_subjects::ActiveModel {
            id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
            student_id: sea_orm::ActiveValue::Set(student_id),
            school_history_id: sea_orm::ActiveValue::Set(school_history_id),
            subject_name: sea_orm::ActiveValue::Set(subject_name),
            subject_group: sea_orm::ActiveValue::Set(subject_group),
            term_type: sea_orm::ActiveValue::Set(term_type),
            final_grade: sea_orm::ActiveValue::Set(final_grade),
            descriptor: sea_orm::ActiveValue::Set(descriptor),
            created_at: sea_orm::ActiveValue::Set(now),
            updated_at: sea_orm::ActiveValue::Set(now),
            deleted_at: sea_orm::ActiveValue::Set(None),
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to insert subject: {}", e)))?
    };

    // Upsert child term grades
    let subject_id = subject_model.id;

    // Delete existing term grades not in the new set
    let existing_term_grades = previous_school_term_grades::Entity::find()
        .filter(previous_school_term_grades::Column::SubjectId.eq(subject_id))
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let new_term_numbers: std::collections::HashSet<i32> = (1..=term_grades.len() as i32).collect();
    for etg in existing_term_grades {
        if !new_term_numbers.contains(&etg.term_number) {
            previous_school_term_grades::Entity::delete_by_id(etg.id)
                .exec(db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to delete term grade: {}", e)))?;
        }
    }

    // Upsert each term grade
    for (i, grade) in term_grades.iter().enumerate() {
        let term_number = (i + 1) as i32;
        let existing_tg = previous_school_term_grades::Entity::find()
            .filter(previous_school_term_grades::Column::SubjectId.eq(subject_id))
            .filter(previous_school_term_grades::Column::TermNumber.eq(term_number))
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(tg_model) = existing_tg {
            let mut am: previous_school_term_grades::ActiveModel = tg_model.into();
            am.grade = sea_orm::ActiveValue::Set(*grade);
            am.updated_at = sea_orm::ActiveValue::Set(now);
            am.update(db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to update term grade: {}", e)))?;
        } else {
            let am = previous_school_term_grades::ActiveModel {
                id: sea_orm::ActiveValue::Set(Uuid::new_v4()),
                subject_id: sea_orm::ActiveValue::Set(subject_id),
                term_number: sea_orm::ActiveValue::Set(term_number),
                grade: sea_orm::ActiveValue::Set(*grade),
                created_at: sea_orm::ActiveValue::Set(now),
                updated_at: sea_orm::ActiveValue::Set(now),
                deleted_at: sea_orm::ActiveValue::Set(None),
            };
            am.insert(db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Failed to insert term grade: {}", e)))?;
        }
    }

    Ok(subject_model)
}
