use uuid::Uuid;
use crate::utils::{AppError, AppResult, parse_datetime, validators::Validator};
use crate::modules::assignment::schema::*;
use crate::modules::class::repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn update_assignment(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    request: UpdateAssignmentRequest,
    teacher_id: Uuid,
) -> AppResult<AssignmentResponse> {
    let assignment = assignment_repo.find_by_id(assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let _class = class_repo.find_by_id(assignment.class_id).await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    if assignment.is_published {
        return Err(AppError::BadRequest("Cannot edit a published assignment".to_string()));
    }

    let title = Validator::validate_optional_title(request.title)?;
    let instructions = Validator::validate_optional_instructions(request.instructions)?;
    Validator::validate_optional_points(request.total_points)?;
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

    let updated = assignment_repo.update_assignment(
        assignment_id,
        title,
        instructions,
        request.total_points,
        request.allows_text_submission,
        request.allows_file_submission,
        allowed_file_types,
        max_file_size_mb,
        due_at,
        request.grading_period_number.map(|q| Some(q)),
        request.component.clone().map(|c| Some(c)),
    ).await?;

    let submission_count = assignment_repo.count_submissions_by_assignment(assignment_id).await?;
    let graded_count = assignment_repo.count_graded_by_assignment(assignment_id).await?;

    Ok(AssignmentResponse {
        id: updated.id,
        class_id: updated.class_id,
        title: updated.title,
        instructions: updated.instructions,
        total_points: updated.total_points,
        allows_text_submission: updated.allows_text_submission,
        allows_file_submission: updated.allows_file_submission,
        allowed_file_types: updated.allowed_file_types,
        max_file_size_mb: updated.max_file_size_mb,
        due_at: updated.due_at.to_string(),
        is_published: updated.is_published,
        order_index: updated.order_index,
        submission_count,
        graded_count,
        grading_period_number: updated.grading_period_number,
        component: updated.component.clone(),
        submission_status: None,
        submission_id: None,
        score: None,
        created_at: updated.created_at.to_string(),
        updated_at: updated.updated_at.to_string(),
    })
}
