use crate::modules::class::repository::ClassRepository;
use crate::utils::error::{AppError, AppResult};
use uuid::Uuid;

pub async fn remove_student(
    class_repo: &ClassRepository,
    class_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
    role: &str,
) -> AppResult<()> {
    let _class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if role == "teacher" && !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only manage your own classes".to_string(),
        ));
    }

    class_repo.remove_student(class_id, student_id).await?;

    Ok(())
}
