use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::admin::ActivityLogRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn soft_delete(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    activity_log_repo: &ActivityLogRepository,
    assignment_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<()> {
    let assignment = assignment_repo.find_by_id(assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let _class = class_repo.find_by_id(assignment.class_id).await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
        return Err(AppError::Forbidden(
            "You can only delete assignments from your own classes".to_string(),
        ));
    }

    assignment_repo.soft_delete(assignment_id).await?;

    let _ = activity_log_repo.create_log(
        teacher_id,
        "assignment_deleted",
        Some(format!("Assignment '{}' deleted", assignment.title)),
    ).await;

    Ok(())
}
