use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::class::repository::ClassRepository;

pub async fn soft_delete(
    class_repo: &ClassRepository,
    class_id: Uuid,
    user_id: Uuid,
    role: &str,
) -> AppResult<()> {
    let _class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if role != "admin" && !class_repo.is_teacher_of_class(user_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only delete your own classes".to_string(),
        ));
    }

    class_repo.remove_all_participants(class_id).await?;
    class_repo.soft_delete(class_id).await?;

    Ok(())
}
