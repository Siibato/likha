use chrono::NaiveDateTime;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl super::AssignmentService {
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

    pub async fn create_assignment(
        &self,
        class_id: Uuid,
        request: CreateAssignmentRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<AssignmentResponse> {
        let _ = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
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

        let max_order = self.assignment_repo.get_max_order_index(class_id).await?;
        let order_index = max_order + 1;

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
                order_index,
                client_id,
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
            order_index: assignment.order_index,
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
        let _ = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let is_teacher_of_class = role == "teacher" && self.class_repo.is_teacher_of_class(user_id, class_id).await?;
        let assignments = if is_teacher_of_class {
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
                order_index: a.order_index,
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

        if role == "teacher" && !self.class_repo.is_teacher_of_class(user_id, assignment.class_id).await? {
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
            order_index: assignment.order_index,
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

        let _class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
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
            order_index: updated.order_index,
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

        let _class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
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

        let _class = self
            .class_repo
            .find_by_id(assignment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
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
            order_index: published.order_index,
            submission_count: 0,
            graded_count: 0,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: published.created_at.to_string(),
            updated_at: published.updated_at.to_string(),
        })
    }

    pub async fn soft_delete(&self, assignment_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
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

        if !self.class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
            return Err(AppError::Forbidden(
                "You can only delete assignments from your own classes".to_string(),
            ));
        }

        self.assignment_repo.soft_delete(assignment_id).await?;

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

    pub async fn reorder_assignments(
        &self,
        class_id: Uuid,
        request: ReorderAssignmentsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only reorder assignments in your own classes".to_string(),
            ));
        }

        if request.assignment_ids.is_empty() {
            return Ok(());
        }

        self.assignment_repo
            .reorder_assignments(class_id, request.assignment_ids)
            .await?;

        Ok(())
    }
}