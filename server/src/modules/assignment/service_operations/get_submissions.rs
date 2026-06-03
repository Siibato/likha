use uuid::Uuid;
use crate::utils::{AppError, AppResult};
use crate::modules::assignment::schema::*;
use crate::modules::class::repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn get_submissions(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    assignment_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<SubmissionListResponse> {
    let assignment = assignment_repo.find_by_id(assignment_id).await?
        .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?;

    let _class = class_repo.find_by_id(assignment.class_id).await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, assignment.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let submissions = assignment_repo.find_submissions_by_assignment(assignment_id).await?;

    let items: Vec<SubmissionListItem> = submissions
        .into_iter()
        .map(|(s, user)| SubmissionListItem {
            id: s.id,
            student_id: s.student_id,
            student_name: user.as_ref().map(|u| u.full_name.clone()).unwrap_or_default(),
            student_username: user.map(|u| u.username).unwrap_or_default(),
            status: s.status,
            submitted_at: s.submitted_at.map(|dt| dt.to_string()),
            score: s.points,
        })
        .collect();

    Ok(SubmissionListResponse { submissions: items })
}
