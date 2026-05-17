use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;
use crate::services::file_service;

const DEFAULT_MAX_FILE_SIZE_MB: i32 = 10;

impl crate::services::assignment::AssignmentService {
    pub async fn upload_file(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
        file_name: String,
        file_type: String,
        file_data: Vec<u8>,
    ) -> AppResult<FileMetadataResponse> {
        let submission = self.assignment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let assignment = self.assignment_repo.find_by_id(submission.assignment_id).await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if submission.status != "draft" && submission.status != "returned" && submission.status != "submitted" {
            return Err(AppError::BadRequest(
                "Can only upload files to draft, returned, or submitted (before deadline) submissions".to_string(),
            ));
        }

        if submission.status == "submitted" {
            let now = chrono::Utc::now().naive_utc();
            if now > assignment.due_at {
                return Err(AppError::BadRequest(
                    "The deadline has passed. You can no longer upload files.".to_string(),
                ));
            }
        }

        if !assignment.allows_file_submission {
            return Err(AppError::BadRequest("This assignment does not accept file submissions".to_string()));
        }

        if let Some(ref allowed) = assignment.allowed_file_types {
            let ext = file_name.rsplit('.').next().unwrap_or("").to_lowercase();
            let allowed_list: Vec<&str> = allowed.split(',').map(|s| s.trim()).collect();
            if !allowed_list.iter().any(|a| a.to_lowercase() == ext) {
                return Err(AppError::BadRequest(format!(
                    "File type '{}' not allowed. Allowed types: {}", ext, allowed
                )));
            }
        }

        let max_size_mb = assignment.max_file_size_mb.unwrap_or(DEFAULT_MAX_FILE_SIZE_MB);
        let max_size_bytes = (max_size_mb as i64) * 1024 * 1024;
        let file_size = file_data.len() as i64;
        if file_size > max_size_bytes {
            return Err(AppError::BadRequest(format!("File exceeds maximum size of {} MB", max_size_mb)));
        }

        let file_hash = file_service::compute_hash(&file_data);

        if let Ok(Some(existing_path)) = self.assignment_repo.find_active_file_path_by_hash(&file_hash).await {
            let file = self.assignment_repo.save_file(
                submission_id, file_name.clone(), file_type.clone(), file_size, existing_path, file_hash,
            ).await?;
            return Ok(FileMetadataResponse {
                id: file.id,
                file_name: file.file_name,
                file_type: file.file_type,
                file_size: file.file_size,
                uploaded_at: file.uploaded_at.to_string(),
            });
        }

        let file_id = Uuid::new_v4();
        let disk_filename = file_service::generate_disk_filename(&file_name, file_id);
        let mut disk_path = PathBuf::from(self.file_storage_path.clone());
        disk_path.push("submission_files");
        disk_path.push(&disk_filename);

        if let Err(e) = file_service::write_file(&disk_path, &file_data, Some(&self.file_encryption_key)).await {
            return Err(AppError::InternalServerError(format!("Failed to write file to disk: {}", e)));
        }

        let file_path = disk_path.to_string_lossy().to_string();

        match self.assignment_repo.save_file(
            submission_id, file_name.clone(), file_type.clone(), file_size, file_path, file_hash,
        ).await {
            Ok(file) => Ok(FileMetadataResponse {
                id: file.id,
                file_name: file.file_name,
                file_type: file.file_type,
                file_size: file.file_size,
                uploaded_at: file.uploaded_at.to_string(),
            }),
            Err(e) => {
                file_service::delete_file(&disk_path).await;
                Err(e)
            }
        }
    }
}
