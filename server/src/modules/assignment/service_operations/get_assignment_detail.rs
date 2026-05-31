use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::schema::*;
use crate::db::repositories::class_repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn get_assignment_detail(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    user_id: Uuid,
    role: &str,
) -> AppResult<AssignmentResponse> {
    let assignment = assignment_repo.find_by_id(assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let _class = class_repo.find_by_id(assignment.class_id).await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if role == "student" && !assignment.is_published {
        return Err(AppError::NotFound("Assignment not found".to_string()));
    }

    if role == "teacher" && !class_repo.is_teacher_of_class(user_id, assignment.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let submission_count = assignment_repo.count_submissions_by_assignment(assignment_id).await?;
    let graded_count = assignment_repo.count_graded_by_assignment(assignment_id).await?;

    Ok(AssignmentResponse {
        id: assignment.id,
        class_id: assignment.class_id,
        title: assignment.title,
        instructions: assignment.instructions,
        total_points: assignment.total_points,
        allows_text_submission: assignment.allows_text_submission,
        allows_file_submission: assignment.allows_file_submission,
        allowed_file_types: assignment.allowed_file_types,
        max_file_size_mb: assignment.max_file_size_mb,
        due_at: assignment.due_at.to_string(),
        is_published: assignment.is_published,
        order_index: assignment.order_index,
        submission_count,
        graded_count,
        grading_period_number: assignment.grading_period_number,
        component: assignment.component.clone(),
        submission_status: None,
        submission_id: None,
        score: None,
        created_at: assignment.created_at.to_string(),
        updated_at: assignment.updated_at.to_string(),
    })
}
