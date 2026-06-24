use crate::modules::assignment::repository::AssignmentRepository;
use crate::modules::assignment::schema::*;
use crate::modules::class::repository::ClassRepository;
use crate::utils::AppResult;
use uuid::Uuid;

pub async fn get_student_assignments(
    assignment_repo: &AssignmentRepository,
    class_repo: &ClassRepository,
    student_id: Uuid,
) -> AppResult<AssignmentListResponse> {
    let classes = class_repo.find_classes_by_student_id(student_id).await?;

    if classes.is_empty() {
        return Ok(AssignmentListResponse {
            assignments: vec![],
        });
    }

    let class_ids: Vec<Uuid> = classes.iter().map(|c| c.id).collect();
    let all_assignments = assignment_repo
        .find_published_by_class_ids(&class_ids)
        .await?;

    if all_assignments.is_empty() {
        return Ok(AssignmentListResponse {
            assignments: vec![],
        });
    }

    let assignment_ids: Vec<Uuid> = all_assignments.iter().map(|a| a.id).collect();

    let (submissions_map, submission_counts, graded_counts) = tokio::try_join!(
        assignment_repo.find_student_submissions_for_assignments(&assignment_ids, student_id),
        assignment_repo.count_submissions_by_assignments(&assignment_ids),
        assignment_repo.count_graded_by_assignments(&assignment_ids),
    )?;

    let responses = all_assignments
        .into_iter()
        .map(|a| {
            let submission = submissions_map.get(&a.id);
            let submission_count = submission_counts.get(&a.id).copied().unwrap_or(0);
            let graded_count = graded_counts.get(&a.id).copied().unwrap_or(0);

            AssignmentResponse {
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
                term_number: a.term_number,
                component: a.component,
                submission_status: submission.map(|s| s.status.clone()),
                submission_id: submission.map(|s| s.id),
                score: submission.and_then(|s| s.points),
                created_at: a.created_at.to_string(),
                updated_at: a.updated_at.to_string(),
            }
        })
        .collect();

    Ok(AssignmentListResponse {
        assignments: responses,
    })
}
