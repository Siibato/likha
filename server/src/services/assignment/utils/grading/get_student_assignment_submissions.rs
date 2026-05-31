use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl crate::services::assignment::AssignmentService {
    pub async fn get_student_assignment_submissions(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<StudentAssignmentSubmissionsResponse> {
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Teacher access required".to_string()));
        }

        let assignments = self.assignment_repo.find_published_by_class_id(class_id).await?;
        let student_name = self.assignment_repo.find_student_name(student_id).await?;

        let mut items = Vec::new();
        for assignment in assignments {
            if let Some(sub) = self.assignment_repo.find_student_submission(assignment.id, student_id).await? {
                items.push(StudentAssignmentSubmissionItem {
                    assignment_id: assignment.id,
                    id: sub.id,
                    student_id: sub.student_id,
                    student_name: student_name.clone(),
                    status: sub.status.clone(),
                    submitted_at: sub.submitted_at.map(|dt| dt.to_string()),
                    score: sub.points,
                });
            }
        }

        Ok(StudentAssignmentSubmissionsResponse { submissions: items })
    }
}
