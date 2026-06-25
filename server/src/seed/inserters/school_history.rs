use chrono::Utc;
use sea_orm::{DatabaseConnection, EntityTrait, Set};

use crate::seed::specs::{PreviousAttendanceSpec, PreviousSubjectSpec, SchoolHistorySpec};
use crate::utils::AppError;
use ::entity::{
    previous_school_attendance, previous_school_subjects, previous_school_term_grades,
    student_school_history,
};

const CHUNK_SIZE: usize = 100;

pub async fn insert_school_history(
    db: &DatabaseConnection,
    specs: &[SchoolHistorySpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = Utc::now().naive_utc();

    let models: Vec<student_school_history::ActiveModel> = specs
        .iter()
        .map(|spec| student_school_history::ActiveModel {
            id: Set(spec.id),
            student_id: Set(spec.student_id),
            school_name: Set(spec.school_name.clone()),
            school_id: Set(spec.school_id.clone()),
            grade_level: Set(spec.grade_level.clone()),
            school_year: Set(spec.school_year.clone()),
            section: Set(spec.section.clone()),
            date_from: Set(spec.date_from),
            date_to: Set(spec.date_to),
            record_type: Set(spec.record_type.clone()),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        student_school_history::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_previous_subjects(
    db: &DatabaseConnection,
    specs: &[PreviousSubjectSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = Utc::now().naive_utc();

    let mut subject_models: Vec<previous_school_subjects::ActiveModel> = Vec::new();
    let mut term_grade_models: Vec<previous_school_term_grades::ActiveModel> = Vec::new();

    for spec in specs {
        subject_models.push(previous_school_subjects::ActiveModel {
            id: Set(spec.id),
            student_id: Set(spec.student_id),
            school_history_id: Set(spec.school_history_id),
            subject_name: Set(spec.subject_name.clone()),
            subject_group: Set(spec.subject_group.clone()),
            term_type: Set(spec.term_type.clone()),
            final_grade: Set(spec.final_grade),
            descriptor: Set(spec.descriptor.clone()),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        });

        for (i, grade) in spec.term_grades.iter().enumerate() {
            let term_number = (i + 1) as i32;
            term_grade_models.push(previous_school_term_grades::ActiveModel {
                id: Set(uuid::Uuid::new_v4()),
                subject_id: Set(spec.id),
                term_number: Set(term_number),
                grade: Set(*grade),
                created_at: Set(now),
                updated_at: Set(now),
                deleted_at: Set(None),
            });
        }
    }

    for chunk in subject_models.chunks(CHUNK_SIZE) {
        previous_school_subjects::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    for chunk in term_grade_models.chunks(CHUNK_SIZE) {
        previous_school_term_grades::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_previous_attendance(
    db: &DatabaseConnection,
    specs: &[PreviousAttendanceSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = Utc::now().naive_utc();

    let models: Vec<previous_school_attendance::ActiveModel> = specs
        .iter()
        .map(|spec| previous_school_attendance::ActiveModel {
            id: Set(spec.id),
            student_id: Set(spec.student_id),
            school_history_id: Set(spec.school_history_id),
            school_year: Set(spec.school_year.clone()),
            month: Set(spec.month.clone()),
            school_days: Set(spec.school_days),
            days_present: Set(spec.days_present),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        previous_school_attendance::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
