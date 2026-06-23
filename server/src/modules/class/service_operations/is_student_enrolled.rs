use crate::modules::class::repository::ClassRepository;
use crate::utils::AppResult;
use uuid::Uuid;

pub async fn is_student_enrolled(
    class_repo: &ClassRepository,
    class_id: Uuid,
    student_id: Uuid,
) -> AppResult<bool> {
    class_repo.is_student_enrolled(class_id, student_id).await
}
