use chrono::Utc;
use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};

use crate::seed::specs::{PreviousAttendanceSpec, PreviousSubjectSpec, SchoolHistorySpec};
use crate::utils::AppError;
use ::entity::{
    previous_school_attendance, previous_school_subjects, previous_school_term_grades,
    student_school_history,
};

pub async fn insert_school_history(
    db: &DatabaseConnection,
    specs: &[SchoolHistorySpec],
) -> Result<(), AppError> {
    let now = Utc::now().naive_utc();

    for spec in specs {
        let am = student_school_history::ActiveModel {
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
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_previous_subjects(
    db: &DatabaseConnection,
    specs: &[PreviousSubjectSpec],
) -> Result<(), AppError> {
    let now = Utc::now().naive_utc();

    for spec in specs {
        let am = previous_school_subjects::ActiveModel {
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
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;

        // Insert child term grades
        for (i, grade) in spec.term_grades.iter().enumerate() {
            let term_number = (i + 1) as i32;
            let tg_am = previous_school_term_grades::ActiveModel {
                id: Set(uuid::Uuid::new_v4()),
                subject_id: Set(spec.id),
                term_number: Set(term_number),
                grade: Set(*grade),
                created_at: Set(now),
                updated_at: Set(now),
                deleted_at: Set(None),
            };
            tg_am
                .insert(db)
                .await
                .map_err(|e| AppError::InternalServerError(e.to_string()))?;
        }
    }

    Ok(())
}

pub async fn insert_previous_attendance(
    db: &DatabaseConnection,
    specs: &[PreviousAttendanceSpec],
) -> Result<(), AppError> {
    let now = Utc::now().naive_utc();

    for spec in specs {
        let am = previous_school_attendance::ActiveModel {
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
        };
        am.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
