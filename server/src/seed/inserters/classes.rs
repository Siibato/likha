use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};

use crate::modules::class::repository::ClassRepository;
use crate::seed::specs::{ClassSpec, EnrollmentSpec};
use crate::utils::AppError;
use ::entity::classes;

pub async fn insert_classes(db: &DatabaseConnection, specs: &[ClassSpec]) -> Result<(), AppError> {
    let repo = ClassRepository::new(db.clone());

    for spec in specs {
        repo.create_class(
            spec.title.clone(),
            spec.description.clone(),
            Some(spec.id),
            spec.is_advisory,
        )
        .await?;

        let class = classes::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("Class {} not found", spec.id)))?;

        let mut am: classes::ActiveModel = class.into();
        am.grade_level = Set(spec.grade_level.clone());
        am.school_year = Set(spec.school_year.clone());
        am.is_archived = Set(spec.is_archived);
        am.created_at = Set(spec.created_at);
        am.updated_at = Set(spec.created_at);
        am.deleted_at = Set(spec.deleted_at);
        am.update(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn insert_enrollments(
    db: &DatabaseConnection,
    specs: &[EnrollmentSpec],
) -> Result<(), AppError> {
    let repo = ClassRepository::new(db.clone());

    for spec in specs {
        repo.add_participant(spec.class_id, spec.user_id).await?;
    }

    Ok(())
}
