use uuid::Uuid;
use crate::utils::AppResult;

impl crate::services::class::ClassService {
    pub async fn is_student_enrolled(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<bool> {
        self.class_repo.is_student_enrolled(class_id, student_id).await
    }
}
