use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};
use uuid::Uuid;

use crate::seed::specs::{GradeItemSpec, GradeRecordSpec, GradeScoreSpec, TermGradeSpec};
use crate::utils::AppError;
use ::entity::{grade_items, grade_record, grade_scores, term_grades};

pub async fn insert_grade_items(
    db: &DatabaseConnection,
    specs: &[GradeItemSpec],
    now: chrono::NaiveDateTime,
) -> Result<(), AppError> {
    for spec in specs {
        let item = grade_items::ActiveModel {
            id: Set(spec.id),
            class_id: Set(spec.class_id),
            title: Set(spec.title.clone()),
            component: Set(spec.component.clone()),
            term_number: Set(Some(spec.term_number)),
            total_points: Set(spec.total_points),
            source_type: Set(spec.source_type.clone()),
            source_id: Set(spec.source_id.clone()),
            order_index: Set(spec.order_index),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        item.insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_grade_records(
    db: &DatabaseConnection,
    specs: &[GradeRecordSpec],
    now: chrono::NaiveDateTime,
) -> Result<(), AppError> {
    for spec in specs {
        let record = grade_record::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(spec.class_id),
            term_number: Set(Some(spec.term_number)),
            ww_weight: Set(spec.ww_weight),
            pt_weight: Set(spec.pt_weight),
            qa_weight: Set(spec.qa_weight),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        record
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
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
        score
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_term_grades(
    db: &DatabaseConnection,
    specs: &[TermGradeSpec],
    now: chrono::NaiveDateTime,
) -> Result<(), AppError> {
    for spec in specs {
        let grade = term_grades::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(spec.class_id),
            student_id: Set(spec.student_id),
            term_number: Set(spec.term_number),
            initial_grade: Set(spec.initial_grade),
            transmuted_grade: Set(spec.transmuted_grade),
            is_locked: Set(spec.is_locked),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };
        grade
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
