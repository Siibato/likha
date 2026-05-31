use uuid::Uuid;
use crate::utils::AppResult;
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn get_student_assignments(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<StudentAssignmentListResponse> {
        let assignments = self.assignment_repo.find_published_by_class_id(class_id).await?;

        let mut items = Vec::new();
        for a in assignments {
            let submission = self.assignment_repo.find_student_submission(a.id, student_id).await?;

            items.push(StudentAssignmentListItem {
                id: a.id,
                title: a.title,
                total_points: a.total_points,
                allows_text_submission: a.allows_text_submission,
                allows_file_submission: a.allows_file_submission,
                due_at: a.due_at.to_string(),
                is_published: a.is_published,
                submission_status: submission.as_ref().map(|s| s.status.clone()),
                submission_id: submission.as_ref().map(|s| s.id),
                score: submission.and_then(|s| s.points),
            });
        }

        Ok(StudentAssignmentListResponse { assignments: items })
    }
}
