use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl super::LearningMaterialService {
    pub async fn verify_teacher_owns_class(&self, class_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let _ = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only manage materials in your own classes".to_string(),
            ));
        }

        Ok(())
    }

    pub async fn verify_student_enrolled(&self, class_id: Uuid, student_id: Uuid) -> AppResult<()> {
        let is_enrolled = self
            .class_repo
            .is_student_enrolled(class_id, student_id)
            .await?;

        if !is_enrolled {
            return Err(AppError::Forbidden(
                "You must be enrolled in this class to view materials".to_string(),
            ));
        }

        Ok(())
    }
}