use futures::future::try_join_all;
use uuid::Uuid;
use crate::utils::AppResult;
use crate::modules::assignment::schema::*;
use crate::modules::class::repository::ClassRepository;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn get_student_assignments(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    student_id: Uuid,
) -> AppResult<AssignmentListResponse> {
    let classes = class_repo.find_classes_by_student_id(student_id).await?;

    let per_class_futures = classes
        .iter()
        .map(|class| assignment_repo.find_published_by_class_id(class.id));
    let all_assignments: Vec<_> = try_join_all(per_class_futures)
        .await?
        .into_iter()
        .flatten()
        .collect();

    let response_futures = all_assignments.iter().map(|a| async move {
        let (submission, submission_count, graded_count) = tokio::try_join!(
            assignment_repo.find_student_submission(a.id, student_id),
            assignment_repo.count_submissions_by_assignment(a.id),
            assignment_repo.count_graded_by_assignment(a.id),
        )?;
        Ok::<AssignmentResponse, crate::utils::AppError>(AssignmentResponse {
            id: a.id,
            class_id: a.class_id,
            title: a.title.clone(),
            instructions: a.instructions.clone(),
            total_points: a.total_points,
            allows_text_submission: a.allows_text_submission,
            allows_file_submission: a.allows_file_submission,
            allowed_file_types: a.allowed_file_types.clone(),
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
        })
    });

    let responses = try_join_all(response_futures).await?;
    Ok(AssignmentListResponse { assignments: responses })
}
