use chrono::Utc;
use sea_orm::{DatabaseConnection, EntityTrait, Set};
use uuid::Uuid;

use crate::seed::specs::{ClassSpec, EnrollmentSpec};
use crate::utils::AppError;
use ::entity::{classes, class_participants};

const CHUNK_SIZE: usize = 100;

pub async fn insert_classes(db: &DatabaseConnection, specs: &[ClassSpec]) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let models: Vec<classes::ActiveModel> = specs
        .iter()
        .map(|spec| classes::ActiveModel {
            id: Set(spec.id),
            title: Set(spec.title.clone()),
            description: Set(spec.description.clone()),
            is_archived: Set(spec.is_archived),
            created_at: Set(spec.created_at),
            updated_at: Set(spec.created_at),
            deleted_at: Set(spec.deleted_at),
            grade_level: Set(spec.grade_level.clone()),
            school_year: Set(spec.school_year.clone()),
            term_type: Set("term".to_string()),
            is_advisory: Set(spec.is_advisory),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        classes::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_enrollments(
    db: &DatabaseConnection,
    specs: &[EnrollmentSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = Utc::now().naive_utc();
    let models: Vec<class_participants::ActiveModel> = specs
        .iter()
        .map(|spec| class_participants::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(spec.class_id),
            user_id: Set(spec.user_id),
            joined_at: Set(now),
            updated_at: Set(now),
            removed_at: Set(None),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        class_participants::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
