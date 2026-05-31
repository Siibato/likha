use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::services::file_service;

impl crate::services::assignment::AssignmentService {
    pub async fn download_file(
        &self,
        file_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<(String, String, Vec<u8>)> {
        let file = self.assignment_repo.find_file_by_id(file_id).await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let submission = self.assignment_repo.find_submission_by_id(file.submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if role == "teacher" {
            let assignment = self.assignment_repo.find_by_id(submission.assignment_id).await?
                .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;
            if !self.class_repo.is_teacher_of_class(user_id, assignment.class_id).await? {
                return Err(AppError::Forbidden("Access denied".to_string()));
            }
        } else if submission.student_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let file_path = file.file_path
            .ok_or_else(|| AppError::NotFound("File data not available".to_string()))?;

        let file_bytes = file_service::read_file(&PathBuf::from(&file_path), Some(&self.file_encryption_key))
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to read file from disk: {}", e)))?;

        Ok((file.file_name, file.file_type, file_bytes))
    }
}
