use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};

use crate::modules::assignment::repository::AssignmentRepository;
use crate::seed::specs::AssignmentSpec;
use crate::utils::AppError;
use ::entity::assignments;

pub async fn insert_assignment(
    db: &DatabaseConnection,
    spec: &AssignmentSpec,
) -> Result<(), AppError> {
    let repo = AssignmentRepository::new(db.clone());
    let created_at = spec.created_at;

    repo.create_assignment(
        spec.class_id,
        spec.title.clone(),
        spec.instructions.clone(),
        spec.total_points,
        spec.allows_text_submission,
        spec.allows_file_submission,
        None, // min_words
        None, // max_words
        spec.due_at,
        0, // order_index
        Some(spec.id),
        false, // is_draft
        Some(spec.term_number),
        Some(spec.component.clone()),
    )
    .await?;

    let assignment = assignments::Entity::find_by_id(spec.id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?
        .ok_or_else(|| AppError::NotFound(format!("Assignment {} not found", spec.id)))?;

    let mut am: assignments::ActiveModel = assignment.into();
    am.created_at = Set(created_at);
    am.updated_at = Set(created_at);
    am.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    if spec.deleted_at.is_none() {
        repo.publish_assignment(spec.id).await?;
    }

    if let Some(deleted_at) = spec.deleted_at {
        let assignment = assignments::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("Assignment {} not found", spec.id)))?;
        let mut am: assignments::ActiveModel = assignment.into();
        am.deleted_at = Set(Some(deleted_at));
        am.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
