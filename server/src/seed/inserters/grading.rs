use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};
use uuid::Uuid;

use crate::modules::grading::repository::GradeComputationRepository;
use crate::seed::specs::{GradeRecordSpec, GradeScoreSpec, PeriodGradeSpec};
use crate::utils::AppError;
use ::entity::{grade_scores, period_grades};

pub async fn insert_grade_records(
    db: &DatabaseConnection,
    specs: &[GradeRecordSpec],
) -> Result<(), AppError> {
    let repo = GradeComputationRepository::new(db.clone());

    for spec in specs {
        repo.setup_defaults(spec.class_id, &spec.grading_period_type)
            .await?;
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
