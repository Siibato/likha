use uuid::Uuid;
use crate::utils::{AppError, AppResult, parse_datetime, validators::Validator};
use crate::modules::assignment::schema::*;
use crate::modules::admin::ActivityLogRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn create_assignment(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    activity_log_repo: &ActivityLogRepository,
    class_id: Uuid,
    request: CreateAssignmentRequest,
    teacher_id: Uuid,
    client_id: Option<Uuid>,
) -> AppResult<AssignmentResponse> {
    let _ = class_repo.find_by_id(class_id).await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only create assignments in your own classes".to_string(),
        ));
    }

    let title = Validator::validate_title(&request.title)?;
    let instructions = Validator::validate_instructions(&request.instructions)?;
    Validator::validate_points(request.total_points)?;
    if let Some(max_size) = request.max_file_size_mb {
        Validator::validate_max_file_size(max_size)?;
    }

    let due_at = parse_datetime(&request.due_at)?;

    let max_order = assignment_repo.get_max_order_index(class_id).await?;
    let order_index = max_order + 1;

    let assignment = assignment_repo.create_assignment(
        class_id,
        title,
        instructions,
        request.total_points,
        request.allows_text_submission,
        request.allows_file_submission,
        request.allowed_file_types,
        request.max_file_size_mb,
        due_at,
        order_index,
        client_id,
        request.is_published.unwrap_or(false),
        request.grading_period_number,
        request.component.clone(),
    ).await?;

    let _ = activity_log_repo.create_log(
        teacher_id,
        "assignment_created",
        Some(format!("Assignment '{}' created", assignment.title)),
    ).await;

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
        submission_count: 0,
        graded_count: 0,
        grading_period_number: assignment.grading_period_number,
        component: assignment.component.clone(),
        submission_status: None,
        submission_id: None,
        score: None,
        created_at: assignment.created_at.to_string(),
        updated_at: assignment.updated_at.to_string(),
    })
}
