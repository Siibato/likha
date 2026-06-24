use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::class::repository::ClassRepository;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

pub async fn reorder_assignments(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    class_id: Uuid,
    assignment_ids: Vec<Uuid>,
    teacher_id: Uuid,
) -> AppResult<()> {
    let _class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only reorder assignments in your own classes".to_string(),
        ));
    }

    if assignment_ids.is_empty() {
        return Ok(());
    }

    assignment_repo
        .reorder_assignments(class_id, assignment_ids)
        .await?;

    Ok(())
}
