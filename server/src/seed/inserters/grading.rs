use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};
use uuid::Uuid;

use crate::seed::specs::{GradeRecordSpec, GradeScoreSpec, PeriodGradeSpec};
use crate::utils::AppError;
use ::entity::{grade_record, grade_scores, period_grades};

pub async fn insert_grade_records(
    db: &DatabaseConnection,
    specs: &[GradeRecordSpec],
    now: chrono::NaiveDateTime,
) -> Result<(), AppError> {
    for spec in specs {
        let record = grade_record::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(spec.class_id),
            grading_period_number: Set(Some(spec.grading_period_number)),
            ww_weight: Set(spec.ww_weight),
            pt_weight: Set(spec.pt_weight),
            qa_weight: Set(spec.qa_weight),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        record.insert(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_grade_scores(
    db: &DatabaseConnection,
    specs: &[GradeScoreSpec],
    now: chrono::NaiveDateTime,
) -> Result<(), AppError> {
    for spec in specs {
        let score = grade_scores::ActiveModel {
            id: Set(Uuid::new_v4()),
            grade_item_id: Set(spec.grade_item_id),
            student_id: Set(spec.student_id),
            score: Set(spec.score),
            is_auto_populated: Set(spec.is_auto_populated),
            override_score: Set(spec.override_score),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        score.insert(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_period_grades(
    db: &DatabaseConnection,
    specs: &[PeriodGradeSpec],
    now: chrono::NaiveDateTime,
) -> Result<(), AppError> {
    for spec in specs {
        let grade = period_grades::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(spec.class_id),
            student_id: Set(spec.student_id),
            grading_period_number: Set(spec.grading_period_number),
            initial_grade: Set(spec.initial_grade),
            transmuted_grade: Set(spec.transmuted_grade),
            is_locked: Set(spec.is_locked),
            computed_at: Set(spec.computed_at),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        grade.insert(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
