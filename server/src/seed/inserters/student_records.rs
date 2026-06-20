use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};
use chrono::Utc;

use crate::seed::specs::{AttendanceSpec, CoreValuesSpec};
use crate::utils::AppError;
use ::entity::{attendance_records, core_values_records};

pub async fn insert_attendance_records(
    db: &DatabaseConnection,
    specs: &[AttendanceSpec],
) -> Result<(), AppError> {
    let now = Utc::now().naive_utc();

    for spec in specs {
        let am = attendance_records::ActiveModel {
            id: Set(spec.id),
            student_id: Set(spec.student_id),
            class_id: Set(spec.class_id),
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

pub async fn insert_core_values_records(
    db: &DatabaseConnection,
    specs: &[CoreValuesSpec],
) -> Result<(), AppError> {
    let now = Utc::now().naive_utc();

    for spec in specs {
        let am = core_values_records::ActiveModel {
            id: Set(spec.id),
            student_id: Set(spec.student_id),
            class_id: Set(spec.class_id),
            school_year: Set(spec.school_year.clone()),
            term_number: Set(spec.term_number),
            core_value_id: Set(spec.core_value_id),
            marking: Set(spec.marking.clone()),
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
