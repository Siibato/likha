use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::{parse_datetime, validators::Validator};
use crate::schema::assignment_schema::*;
use crate::services::grade_computation::auto_populate;

impl super::AssignmentService {

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

        let title = Validator::validate_title(&request.title)?;
        let instructions = Validator::validate_instructions(&request.instructions)?;
        Validator::validate_points(request.total_points)?;
        Validator::validate_submission_type(&request.submission_type)?;
        if let Some(max_size) = request.max_file_size_mb {
            Validator::validate_max_file_size(max_size)?;
        }

        let due_at = parse_datetime(&request.due_at)?;

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
                request.is_published.unwrap_or(false),
                request.quarter,
                request.component.clone(),
                request.no_submission_required,
            )
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_created",
                Some(format!("Assignment '{}' created", assignment.title)),
            )
            .await;

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
            quarter: assignment.quarter,
            component: assignment.component.clone(),
            no_submission_required: assignment.no_submission_required,
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
                    submission.and_then(|s| s.points),
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
                quarter: a.quarter,
                component: a.component.clone(),
                no_submission_required: a.no_submission_required,
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
                score: submission.and_then(|s| s.points),
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

        let _class = self
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
            quarter: assignment.quarter,
            component: assignment.component.clone(),
            no_submission_required: assignment.no_submission_required,
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

        let title = Validator::validate_optional_title(request.title)?;
        let instructions = Validator::validate_optional_instructions(request.instructions)?;
        Validator::validate_optional_points(request.total_points)?;
        Validator::validate_optional_submission_type(request.submission_type.clone())?;

        Validator::validate_optional_max_file_size(request.max_file_size_mb)?;

        let due_at = match &request.due_at {
            Some(s) => Some(parse_datetime(s)?),
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
                title,
                instructions,
                request.total_points,
                request.submission_type,
                allowed_file_types,
                max_file_size_mb,
                due_at,
                request.quarter.map(|q| Some(q)),
                request.component.clone().map(|c| Some(c)),
                request.no_submission_required.map(|n| Some(n)),
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
            quarter: updated.quarter,
            component: updated.component.clone(),
            no_submission_required: updated.no_submission_required,
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

        self.assignment_repo
            .soft_delete(assignment_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_deleted",
                Some(format!("Assignment '{}' deleted", assignment.title)),
            )
            .await;

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

        // Auto-create linked grade item if grading metadata present
        if let (Some(quarter), Some(ref component)) = (published.quarter, &published.component) {
            let _ = auto_populate::create_linked_grade_item(
                &self.db, "assignment", published.id, published.class_id,
                &published.title, component, quarter,
                published.total_points as f64,
                false,
            ).await;
        }

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_published",
                Some(format!("Assignment '{}' published", published.title)),
            )
            .await;

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
            quarter: published.quarter,
            component: published.component.clone(),
            no_submission_required: published.no_submission_required,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: published.created_at.to_string(),
            updated_at: published.updated_at.to_string(),
        })
    }

    pub async fn unpublish_assignment(
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

        if !assignment.is_published {
            return Err(AppError::BadRequest("Assignment is not published".to_string()));
        }

        let unpublished = self
            .assignment_repo
            .unpublish_assignment(assignment_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_unpublished",
                Some(format!("Assignment '{}' unpublished", unpublished.title)),
            )
            .await;

        Ok(AssignmentResponse {
            id: unpublished.id,
            class_id: unpublished.class_id,
            title: unpublished.title,
            instructions: unpublished.instructions,
            total_points: unpublished.total_points,
            submission_type: unpublished.submission_type,
            allowed_file_types: unpublished.allowed_file_types,
            max_file_size_mb: unpublished.max_file_size_mb,
            due_at: unpublished.due_at.to_string(),
            is_published: unpublished.is_published,
            order_index: unpublished.order_index,
            submission_count: 0,
            graded_count: 0,
            quarter: unpublished.quarter,
            component: unpublished.component.clone(),
            no_submission_required: unpublished.no_submission_required,
            submission_status: None,
            submission_id: None,
            score: None,
            created_at: unpublished.created_at.to_string(),
            updated_at: unpublished.updated_at.to_string(),
        })
    }

    pub async fn soft_delete(&self, assignment_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
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
            return Err(AppError::Forbidden(
                "You can only delete assignments from your own classes".to_string(),
            ));
        }

        self.assignment_repo.soft_delete(assignment_id).await?;

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