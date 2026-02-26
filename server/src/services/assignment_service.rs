use chrono::NaiveDateTime;
use sea_orm::DatabaseConnection;
use uuid::Uuid;
use md5;

use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::assignment_repository::AssignmentRepository;
use crate::db::repositories::change_log_repository::ChangeLogRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::schema::assignment_schema::*;
use crate::utils::error::{AppError, AppResult};

const DEFAULT_MAX_FILE_SIZE_MB: i32 = 10;

pub struct AssignmentService {
    assignment_repo: AssignmentRepository,
    class_repo: ClassRepository,
    activity_log_repo: ActivityLogRepository,
    change_log_repo: ChangeLogRepository,
}

impl AssignmentService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            assignment_repo: AssignmentRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db.clone()),
            change_log_repo: ChangeLogRepository::new(db),
        }
    }

    fn parse_datetime(s: &str) -> AppResult<NaiveDateTime> {
        NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S")
            .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S"))
            .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f"))
            .map_err(|_| {
                AppError::BadRequest(format!(
                    "Invalid datetime format: {}. Use YYYY-MM-DDTHH:MM:SS",
                    s
                ))
            })
    }

    // ===== ASSIGNMENT CRUD =====

    pub async fn create_assignment(
        &self,
        class_id: Uuid,
        request: CreateAssignmentRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentResponse> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only create assignments in your own classes".to_string(),
            ));
        }

        let title = request.title.trim().to_string();
        if title.is_empty() || title.len() > 200 {
            return Err(AppError::BadRequest(
                "Title is required and must be at most 200 characters".to_string(),
            ));
        }

        let instructions = request.instructions.trim().to_string();
        if instructions.is_empty() || instructions.len() > 10000 {
            return Err(AppError::BadRequest(
                "Instructions are required and must be at most 10000 characters".to_string(),
            ));
        }

        if request.total_points < 1 || request.total_points > 1000 {
            return Err(AppError::BadRequest(
                "Total points must be between 1 and 1000".to_string(),
            ));
        }

        let valid_types = ["text", "file", "text_or_file"];
        if !valid_types.contains(&request.submission_type.as_str()) {
            return Err(AppError::BadRequest(format!(
                "Invalid submission type. Must be one of: {:?}",
                valid_types
            )));
        }

        if let Some(max_size) = request.max_file_size_mb {
            if max_size < 1 || max_size > 50 {
                return Err(AppError::BadRequest(
                    "Max file size must be between 1 and 50 MB".to_string(),
                ));
            }
        }

        let due_at = Self::parse_datetime(&request.due_at)?;

        let assignment = self
            .assignment_repo
            .create_assignment(
                class_id,
                title,
                instructions,
                request.total_points,
                request.submission_type,
                request.allowed_file_types,
                request.max_file_size_mb,
                due_at,
            )
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_created",
                Some(teacher_id),
                Some(format!("Assignment '{}' created", assignment.title)),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment",
            assignment.id,
            "create",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "title": assignment.title,
                "total_points": assignment.total_points,
            })).unwrap_or_default()),
        ).await;

        Ok(AssignmentResponse {
            id: assignment.id,
            class_id: assignment.class_id,
            title: assignment.title,
            instructions: assignment.instructions,
            total_points: assignment.total_points,
            submission_type: assignment.submission_type,
            allowed_file_types: assignment.allowed_file_types,
            max_file_size_mb: assignment.max_file_size_mb,
            due_at: assignment.due_at.to_string(),
            is_published: assignment.is_published,
            submission_count: 0,
            graded_count: 0,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: assignment.created_at.to_string(),
            updated_at: assignment.updated_at.to_string(),
        })
    }

    pub async fn get_assignments(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssignmentListResponse> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let assignments = if role == "teacher" && class.teacher_id == user_id {
            self.assignment_repo.find_by_class_id(class_id).await?
        } else {
            self.assignment_repo
                .find_published_by_class_id(class_id)
                .await?
        };

        let mut responses = Vec::new();
        for a in assignments {
            let submission_count = self
                .assignment_repo
                .count_submissions_by_assignment(a.id)
                .await?;
            let graded_count = self
                .assignment_repo
                .count_graded_by_assignment(a.id)
                .await?;

            // For students, include their submission status
            let (submission_status, submission_id, score) = if role == "student" {
                let submission = self
                    .assignment_repo
                    .find_student_submission(a.id, user_id)
                    .await?;
                (
                    submission.as_ref().map(|s| s.status.clone()),
                    submission.as_ref().map(|s| s.id),
                    submission.and_then(|s| s.score),
                )
            } else {
                (None, None, None)
            };

            responses.push(AssignmentResponse {
                id: a.id,
                class_id: a.class_id,
                title: a.title,
                instructions: a.instructions,
                total_points: a.total_points,
                submission_type: a.submission_type,
                allowed_file_types: a.allowed_file_types,
                max_file_size_mb: a.max_file_size_mb,
                due_at: a.due_at.to_string(),
                is_published: a.is_published,
                submission_count,
                graded_count,
                submission_status,
                submission_id,
                score,
                created_at: a.created_at.to_string(),
                updated_at: a.updated_at.to_string(),
            });
        }

        Ok(AssignmentListResponse {
            assignments: responses,
        })
    }

    pub async fn get_student_assignments(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<StudentAssignmentListResponse> {
        let assignments = self
            .assignment_repo
            .find_published_by_class_id(class_id)
            .await?;

        let mut items = Vec::new();
        for a in assignments {
            let submission = self
                .assignment_repo
                .find_student_submission(a.id, student_id)
                .await?;

            items.push(StudentAssignmentListItem {
                id: a.id,
                title: a.title,
                total_points: a.total_points,
                submission_type: a.submission_type,
                due_at: a.due_at.to_string(),
                is_published: a.is_published,
                submission_status: submission.as_ref().map(|s| s.status.clone()),
                submission_id: submission.as_ref().map(|s| s.id),
                score: submission.and_then(|s| s.score),
            });
        }

        Ok(StudentAssignmentListResponse { assignments: items })
    }

    pub async fn get_assignment_detail(
        &self,
        assignment_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssignmentResponse> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if role == "student" && !assignment.is_published {
            return Err(AppError::NotFound("Assignment not found".to_string()));
        }

        if role == "teacher" && class.teacher_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submission_count = self
            .assignment_repo
            .count_submissions_by_assignment(assignment_id)
            .await?;
        let graded_count = self
            .assignment_repo
            .count_graded_by_assignment(assignment_id)
            .await?;

        Ok(AssignmentResponse {
            id: assignment.id,
            class_id: assignment.class_id,
            title: assignment.title,
            instructions: assignment.instructions,
            total_points: assignment.total_points,
            submission_type: assignment.submission_type,
            allowed_file_types: assignment.allowed_file_types,
            max_file_size_mb: assignment.max_file_size_mb,
            due_at: assignment.due_at.to_string(),
            is_published: assignment.is_published,
            submission_count,
            graded_count,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: assignment.created_at.to_string(),
            updated_at: assignment.updated_at.to_string(),
        })
    }

    pub async fn update_assignment(
        &self,
        assignment_id: Uuid,
        request: UpdateAssignmentRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentResponse> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assignment.is_published {
            return Err(AppError::BadRequest(
                "Cannot edit a published assignment".to_string(),
            ));
        }

        if let Some(ref title) = request.title {
            if title.trim().is_empty() || title.len() > 200 {
                return Err(AppError::BadRequest(
                    "Title must be between 1 and 200 characters".to_string(),
                ));
            }
        }

        if let Some(ref instructions) = request.instructions {
            if instructions.trim().is_empty() || instructions.len() > 10000 {
                return Err(AppError::BadRequest(
                    "Instructions must be between 1 and 10000 characters".to_string(),
                ));
            }
        }

        if let Some(tp) = request.total_points {
            if tp < 1 || tp > 1000 {
                return Err(AppError::BadRequest(
                    "Total points must be between 1 and 1000".to_string(),
                ));
            }
        }

        if let Some(ref st) = request.submission_type {
            let valid_types = ["text", "file", "text_or_file"];
            if !valid_types.contains(&st.as_str()) {
                return Err(AppError::BadRequest(format!(
                    "Invalid submission type. Must be one of: {:?}",
                    valid_types
                )));
            }
        }

        let due_at = match &request.due_at {
            Some(s) => Some(Self::parse_datetime(s)?),
            None => None,
        };

        let allowed_file_types = if request.allowed_file_types.is_some() {
            Some(request.allowed_file_types)
        } else {
            None
        };
        let max_file_size_mb = if request.max_file_size_mb.is_some() {
            Some(request.max_file_size_mb)
        } else {
            None
        };

        let updated = self
            .assignment_repo
            .update_assignment(
                assignment_id,
                request.title,
                request.instructions,
                request.total_points,
                request.submission_type,
                allowed_file_types,
                max_file_size_mb,
                due_at,
            )
            .await?;

        let submission_count = self
            .assignment_repo
            .count_submissions_by_assignment(assignment_id)
            .await?;
        let graded_count = self
            .assignment_repo
            .count_graded_by_assignment(assignment_id)
            .await?;

        let _ = self.change_log_repo.log_change(
            "assignment",
            assignment_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "title": updated.title,
                "total_points": updated.total_points,
            })).unwrap_or_default()),
        ).await;

        Ok(AssignmentResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            instructions: updated.instructions,
            total_points: updated.total_points,
            submission_type: updated.submission_type,
            allowed_file_types: updated.allowed_file_types,
            max_file_size_mb: updated.max_file_size_mb,
            due_at: updated.due_at.to_string(),
            is_published: updated.is_published,
            submission_count,
            graded_count,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: updated.created_at.to_string(),
            updated_at: updated.updated_at.to_string(),
        })
    }

    pub async fn delete_assignment(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submission_count = self
            .assignment_repo
            .count_submissions_by_assignment(assignment_id)
            .await?;
        if submission_count > 0 {
            return Err(AppError::BadRequest(
                "Cannot delete assignment with existing submissions".to_string(),
            ));
        }

        self.assignment_repo
            .delete_assignment(assignment_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_deleted",
                Some(teacher_id),
                Some(format!("Assignment '{}' deleted", assignment.title)),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment",
            assignment_id,
            "delete",
            teacher_id,
            None,
        ).await;

        Ok(())
    }

    pub async fn publish_assignment(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentResponse> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assignment.is_published {
            return Err(AppError::BadRequest(
                "Assignment is already published".to_string(),
            ));
        }

        let published = self
            .assignment_repo
            .publish_assignment(assignment_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_published",
                Some(teacher_id),
                Some(format!("Assignment '{}' published", published.title)),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment",
            assignment_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "is_published": true,
            })).unwrap_or_default()),
        ).await;

        Ok(AssignmentResponse {
            id: published.id,
            class_id: published.class_id,
            title: published.title,
            instructions: published.instructions,
            total_points: published.total_points,
            submission_type: published.submission_type,
            allowed_file_types: published.allowed_file_types,
            max_file_size_mb: published.max_file_size_mb,
            due_at: published.due_at.to_string(),
            is_published: published.is_published,
            submission_count: 0,
            graded_count: 0,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: published.created_at.to_string(),
            updated_at: published.updated_at.to_string(),
        })
    }

    // ===== STUDENT SUBMISSION FLOW =====

    pub async fn create_or_get_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
        text_content: Option<String>,
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

        // Check submission type compatibility
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
                // Update text content for draft/returned submissions
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
                    .create_submission(assignment_id, student_id)
                    .await?;

                let _ = self.change_log_repo.log_change(
                    "assignment_submission",
                    sub.id,
                    "create",
                    student_id,
                    Some(serde_json::to_string(&serde_json::json!({
                        "assignment_id": assignment_id,
                    })).unwrap_or_default()),
                ).await;

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

        // Validate file type
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

        // Validate file size
        let max_size_mb = assignment.max_file_size_mb.unwrap_or(DEFAULT_MAX_FILE_SIZE_MB);
        let max_size_bytes = (max_size_mb as i64) * 1024 * 1024;
        let file_size = file_data.len() as i64;
        if file_size > max_size_bytes {
            return Err(AppError::BadRequest(format!(
                "File exceeds maximum size of {} MB",
                max_size_mb
            )));
        }

        let file = self
            .assignment_repo
            .save_file(submission_id, file_name, file_type, file_size, file_data)
            .await?;

        Ok(FileMetadataResponse {
            id: file.id,
            file_name: file.file_name,
            file_type: file.file_type,
            file_size: file.file_size,
            uploaded_at: file.uploaded_at.to_string(),
        })
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

        self.assignment_repo.delete_file(file_id).await
    }

    pub async fn submit_assignment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
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

        // Check if late
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
                Some(student_id),
                Some(format!(
                    "Submitted assignment '{}'{}",
                    assignment.title,
                    if is_late { " (late)" } else { "" }
                )),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment_submission",
            submission_id,
            "update",
            student_id,
            Some(serde_json::to_string(&serde_json::json!({
                "status": "submitted",
                "is_late": is_late,
            })).unwrap_or_default()),
        ).await;

        let student_name = self.assignment_repo.find_student_name(student_id).await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(updated, student_name, files))
    }

    // ===== TEACHER: SUBMISSIONS & GRADING =====

    pub async fn get_submissions(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionListResponse> {
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self
            .assignment_repo
            .find_submissions_by_assignment(assignment_id)
            .await?;

        let items: Vec<SubmissionListItem> = submissions
            .into_iter()
            .map(|(s, user)| SubmissionListItem {
                id: s.id,
                student_id: s.student_id,
                student_name: user.map(|u| u.full_name).unwrap_or_default(),
                status: s.status,
                submitted_at: s.submitted_at.map(|dt| dt.to_string()),
                is_late: s.is_late,
                score: s.score,
            })
            .collect();

        Ok(SubmissionListResponse { submissions: items })
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

        // Authorization
        if role == "teacher" {
            let class = self
                .class_repo
                .find_by_id(assignment.class_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;
            if class.teacher_id != user_id {
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

    pub async fn grade_submission(
        &self,
        submission_id: Uuid,
        request: GradeSubmissionRequest,
        teacher_id: Uuid,
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

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "submitted" && submission.status != "returned" && submission.status != "graded" {
            return Err(AppError::BadRequest(format!(
                "Cannot grade a submission with status '{}'",
                submission.status
            )));
        }

        if request.score < 0 || request.score > assignment.total_points {
            return Err(AppError::BadRequest(format!(
                "Score must be between 0 and {}",
                assignment.total_points
            )));
        }

        if let Some(ref feedback) = request.feedback {
            if feedback.len() > 5000 {
                return Err(AppError::BadRequest(
                    "Feedback must be at most 5000 characters".to_string(),
                ));
            }
        }

        let graded = self
            .assignment_repo
            .grade_submission(submission_id, request.score, request.feedback)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_graded",
                Some(teacher_id),
                Some(format!(
                    "Graded assignment '{}' - score: {}/{}",
                    assignment.title, request.score, assignment.total_points
                )),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment_submission",
            submission_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "status": "graded",
                "score": request.score,
            })).unwrap_or_default()),
        ).await;

        let student_name = self
            .assignment_repo
            .find_student_name(graded.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(graded, student_name, files))
    }

    pub async fn return_submission(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
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

        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.status != "submitted" {
            return Err(AppError::BadRequest(
                "Can only return submitted submissions".to_string(),
            ));
        }

        let returned = self
            .assignment_repo
            .return_submission(submission_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_returned",
                Some(teacher_id),
                Some(format!(
                    "Returned assignment '{}' for revision",
                    assignment.title
                )),
            )
            .await;

        let _ = self.change_log_repo.log_change(
            "assignment_submission",
            submission_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "status": "returned",
            })).unwrap_or_default()),
        ).await;

        let student_name = self
            .assignment_repo
            .find_student_name(returned.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(returned, student_name, files))
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

        // Authorization
        if role == "teacher" {
            let assignment = self
                .assignment_repo
                .find_by_id(submission.assignment_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;
            let class = self
                .class_repo
                .find_by_id(assignment.class_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;
            if class.teacher_id != user_id {
                return Err(AppError::Forbidden("Access denied".to_string()));
            }
        } else if submission.student_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        Ok((file.file_name, file.file_type, file.file_data))
    }

    // ===== HELPERS =====

    fn build_submission_response(
        &self,
        submission: ::entity::assignment_submissions::Model,
        student_name: String,
        files: Vec<::entity::submission_files::Model>,
    ) -> AssignmentSubmissionResponse {
        let file_responses: Vec<FileMetadataResponse> = files
            .into_iter()
            .map(|f| FileMetadataResponse {
                id: f.id,
                file_name: f.file_name,
                file_type: f.file_type,
                file_size: f.file_size,
                uploaded_at: f.uploaded_at.to_string(),
            })
            .collect();

        AssignmentSubmissionResponse {
            id: submission.id,
            assignment_id: submission.assignment_id,
            student_id: submission.student_id,
            student_name,
            status: submission.status,
            text_content: submission.text_content,
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            is_late: submission.is_late,
            score: submission.score,
            feedback: submission.feedback,
            graded_at: submission.graded_at.map(|dt| dt.to_string()),
            files: file_responses,
            created_at: submission.created_at.to_string(),
            updated_at: submission.updated_at.to_string(),
        }
    }

    pub async fn get_assignments_metadata(&self) -> AppResult<AssignmentMetadataResponse> {
        let assignments = self.assignment_repo.find_all().await?;
        let count = assignments.len();

        let last_modified = if count > 0 {
            assignments
                .iter()
                .map(|a| a.updated_at)
                .max()
                .unwrap_or_else(|| chrono::Utc::now().naive_utc())
        } else {
            chrono::Utc::now().naive_utc()
        };

        let etag_data = format!("{}-{}", count, last_modified);
        let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

        Ok(AssignmentMetadataResponse {
            last_modified: last_modified.to_string(),
            record_count: count,
            etag,
        })
    }

    /// Soft delete an assignment (marks it deleted for sync, doesn't remove from DB)
    pub async fn soft_delete(&self, assignment_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        // Verify assignment exists and teacher owns the class
        let assignment = self
            .assignment_repo
            .find_by_id(assignment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

        // Verify teacher owns the class
        let class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only delete assignments from your own classes".to_string(),
            ));
        }

        // Mark as deleted
        self.assignment_repo.soft_delete(assignment_id).await?;

        // Log the deletion
        let _ = self.change_log_repo.log_change(
            "assignment",
            assignment_id,
            "delete",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "id": assignment_id,
                "title": assignment.title,
            })).unwrap_or_default()),
        ).await;

        Ok(())
    }
}
