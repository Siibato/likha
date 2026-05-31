use uuid::Uuid;
use crate::utils::AppResult;
use crate::modules::assignment::schema::*;
use crate::db::repositories::class_repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn get_student_assignments(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    student_id: Uuid,
) -> AppResult<AssignmentListResponse> {
    let classes = class_repo.find_classes_by_student_id(student_id).await?;
    
    let mut all_assignments = Vec::new();
    for class in classes {
        let assignments = assignment_repo.find_published_by_class_id(class.id).await?;
        all_assignments.extend(assignments);
    }

    let mut responses = Vec::new();
    for a in all_assignments {
        let submission = assignment_repo.find_student_submission(a.id, student_id).await?;
        let submission_count = assignment_repo.count_submissions_by_assignment(a.id).await?;
        let graded_count = assignment_repo.count_graded_by_assignment(a.id).await?;

        responses.push(AssignmentResponse {
            id: a.id,
            class_id: a.class_id,
            title: a.title,
            instructions: a.instructions,
            total_points: a.total_points,
            allows_text_submission: a.allows_text_submission,
            allows_file_submission: a.allows_file_submission,
            allowed_file_types: a.allowed_file_types,
            max_file_size_mb: a.max_file_size_mb,
            due_at: a.due_at.to_string(),
            is_published: a.is_published,
            order_index: a.order_index,
            submission_count,
            graded_count,
            grading_period_number: a.grading_period_number,
            component: a.component.clone(),
            submission_status: submission.as_ref().map(|s| s.status.clone()),
            submission_id: submission.as_ref().map(|s| s.id),
            score: submission.and_then(|s| s.points),
            created_at: a.created_at.to_string(),
            updated_at: a.updated_at.to_string(),
        });
    }

    Ok(AssignmentListResponse { assignments: responses })
}
