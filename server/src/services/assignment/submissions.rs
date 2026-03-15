use std::path::PathBuf;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;
use crate::services::file_service;

const DEFAULT_MAX_FILE_SIZE_MB: i32 = 10;

impl super::AssignmentService {
    pub async fn create_or_get_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
        text_content: Option<String>,
        submission_id: Option<Uuid>,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if !assignment.is_published {
            return Err(AppError::NotFound("Assignment not found".to_string()));
        }

        let enrolled = self
            .class_repo
            .is_student_enrolled(assignment.class_id, student_id)
            .await?;
        if !enrolled {
            return Err(AppError::Forbidden(
                "You are not enrolled in this class".to_string(),
            ));
        }

        if let Some(ref text) = text_content {
            if !text.is_empty() && assignment.submission_type == "file" {
                return Err(AppError::BadRequest(
                    "This assignment only accepts file submissions".to_string(),
                ));
            }
            if text.len() > 50000 {
                return Err(AppError::BadRequest(
                    "Text content must be at most 50000 characters".to_string(),
                ));
            }
        }

        let submission = match self
            .assignment_repo
            .find_student_submission(assignment_id, student_id)
            .await?
        {
            Some(existing) => {
                if existing.status == "graded" {
                    return Err(AppError::BadRequest(
                        "This submission has already been graded".to_string(),
                    ));
                }
                if existing.status == "submitted" {
                    return Err(AppError::BadRequest(
                        "This submission has already been submitted. Wait for teacher to return it for revision.".to_string(),
                    ));
                }
                if text_content.is_some() {
                    self.assignment_repo
                        .update_submission_text(existing.id, text_content)
                        .await?
                } else {
                    existing
                }
            }
            None => {
                let sub = self
                    .assignment_repo
                    .create_submission(assignment_id, student_id, submission_id)
                    .await?;

                if text_content.is_some() {
                    self.assignment_repo
                        .update_submission_text(sub.id, text_content)
                        .await?
                } else {
                    sub
                }
            }
        };

        let student_name = self.assignment_repo.find_student_name(student_id).await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission.id)
            .await?;

        Ok(self.build_submission_response(submission, student_name, files))
    }

    pub async fn upload_file(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
        file_name: String,
        file_type: String,
        file_data: Vec<u8>,
    ) -> AppResult<FileMetadataResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "draft" && submission.status != "returned" {
            return Err(AppError::BadRequest(
                "Can only upload files to draft or returned submissions".to_string(),
            ));
        }

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if assignment.submission_type == "text" {
            return Err(AppError::BadRequest(
                "This assignment only accepts text submissions".to_string(),
            ));
        }

        if let Some(ref allowed) = assignment.allowed_file_types {
            let ext = file_name
                .rsplit('.')
                .next()
                .unwrap_or("")
                .to_lowercase();
            let allowed_list: Vec<&str> = allowed.split(',').map(|s| s.trim()).collect();
            if !allowed_list.iter().any(|a| a.to_lowercase() == ext) {
                return Err(AppError::BadRequest(format!(
                    "File type '{}' not allowed. Allowed types: {}",
                    ext, allowed
                )));
            }
        }

        let max_size_mb = assignment.max_file_size_mb.unwrap_or(DEFAULT_MAX_FILE_SIZE_MB);
        let max_size_bytes = (max_size_mb as i64) * 1024 * 1024;
        let file_size = file_data.len() as i64;
        if file_size > max_size_bytes {
            return Err(AppError::BadRequest(format!(
                "File exceeds maximum size of {} MB",
                max_size_mb
            )));
        }

        // Compute file hash for deduplication
        let file_hash = file_service::compute_hash(&file_data);

        // Check if this file already exists
        if let Ok(Some(existing_path)) = self.assignment_repo.find_active_file_path_by_hash(&file_hash).await {
            // File already exists, reuse it
            let file = self
                .assignment_repo
                .save_file(submission_id, file_name.clone(), file_type.clone(), file_size, existing_path, file_hash)
                .await?;

            return Ok(FileMetadataResponse {
                id: file.id,
                file_name: file.file_name,
                file_type: file.file_type,
                file_size: file.file_size,
                uploaded_at: file.uploaded_at.to_string(),
            });
        }

        // Generate filename and disk path
        let file_id = Uuid::new_v4();
        let disk_filename = file_service::generate_disk_filename(&file_name, file_id);
        let mut disk_path = PathBuf::from(self.file_storage_path.clone());
        disk_path.push("submission_files");
        disk_path.push(&disk_filename);

        // Write file to disk
        if let Err(e) = file_service::write_file(&disk_path, &file_data).await {
            return Err(AppError::InternalServerError(format!("Failed to write file to disk: {}", e)));
        }

        let file_path = disk_path.to_string_lossy().to_string();

        // Save to database
        match self
            .assignment_repo
            .save_file(submission_id, file_name.clone(), file_type.clone(), file_size, file_path, file_hash)
            .await
        {
            Ok(file) => Ok(FileMetadataResponse {
                id: file.id,
                file_name: file.file_name,
                file_type: file.file_type,
                file_size: file.file_size,
                uploaded_at: file.uploaded_at.to_string(),
            }),
            Err(e) => {
                // DB insert failed, delete the file we just wrote
                file_service::delete_file(&disk_path).await;
                Err(e)
            }
        }
    }

    pub async fn delete_file(
        &self,
        file_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<()> {
        let file = self
            .assignment_repo
            .find_file_by_id(file_id)
            .await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let submission = self
            .assignment_repo
            .find_submission_by_id(file.submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "draft" && submission.status != "returned" {
            return Err(AppError::BadRequest(
                "Can only delete files from draft or returned submissions".to_string(),
            ));
        }

        // Soft delete the DB row
        self.assignment_repo.soft_delete_file(file_id).await?;

        // Check if any other rows reference the same hash
        if let (Some(hash), Some(path)) = (file.file_hash, file.file_path) {
            if let Ok(count) = self.assignment_repo.count_active_by_hash(&hash, file_id).await {
                if count == 0 {
                    // No other references, delete physical file
                    file_service::delete_file(&PathBuf::from(&path)).await;
                }
            }
        }

        Ok(())
    }

    pub async fn submit_assignment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
        text_content: Option<String>,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "draft" && submission.status != "returned" {
            return Err(AppError::BadRequest(format!(
                "Cannot submit a submission with status '{}'",
                submission.status
            )));
        }

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        // Save text content if provided
        if text_content.is_some() {
            self.assignment_repo
                .update_submission_text(submission_id, text_content)
                .await?;
        }

        let now = chrono::Utc::now().naive_utc();
        let is_late = now > assignment.due_at;

        let updated = self
            .assignment_repo
            .update_submission_status(submission_id, "submitted", Some(is_late))
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                student_id,
                "assignment_submitted",
                Some(format!(
                    "Submitted assignment '{}'{}",
                    assignment.title,
                    if is_late { " (late)" } else { "" }
                )),
            )
            .await;

        let student_name = self.assignment_repo.find_student_name(student_id).await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(updated, student_name, files))
    }

    pub async fn get_submission_detail(
        &self,
        submission_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        if role == "teacher" {
            if !self.class_repo.is_teacher_of_class(user_id, assignment.class_id).await? {
                return Err(AppError::Forbidden("Access denied".to_string()));
            }
        } else if submission.student_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let student_name = self
            .assignment_repo
            .find_student_name(submission.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(submission, student_name, files))
    }

    pub async fn download_file(
        &self,
        file_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<(String, String, Vec<u8>)> {
        let file = self
            .assignment_repo
            .find_file_by_id(file_id)
            .await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let submission = self
            .assignment_repo
            .find_submission_by_id(file.submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if role == "teacher" {
            let assignment = self
                .assignment_repo
                .find_by_id(submission.assignment_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;
            if !self.class_repo.is_teacher_of_class(user_id, assignment.class_id).await? {
                return Err(AppError::Forbidden("Access denied".to_string()));
            }
        } else if submission.student_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let file_path = file
            .file_path
            .ok_or_else(|| AppError::NotFound("File data not available".to_string()))?;

        let file_bytes = file_service::read_file(&PathBuf::from(&file_path))
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to read file from disk: {}", e)))?;

        Ok((file.file_name, file.file_type, file_bytes))
    }
}