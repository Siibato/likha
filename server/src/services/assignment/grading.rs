use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assignment_schema::*;

impl super::AssignmentService {
    pub async fn get_submissions(
        &self,
        assignment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionListResponse> {
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

        let submissions = self
            .assignment_repo
            .find_submissions_by_assignment(assignment_id)
            .await?;

        let items: Vec<SubmissionListItem> = submissions
            .into_iter()
            .map(|(s, user)| SubmissionListItem {
                id: s.id,
                student_id: s.student_id,
                student_name: user.as_ref().map(|u| u.full_name.clone()).unwrap_or_default(),
                student_username: user.map(|u| u.username).unwrap_or_default(),
                status: s.status,
                submitted_at: s.submitted_at.map(|dt| dt.to_string()),
                is_late: s.is_late,
                score: s.points,
            })
            .collect();

        Ok(SubmissionListResponse { submissions: items })
    }

    pub async fn grade_submission(
        &self,
        submission_id: Uuid,
        request: GradeSubmissionRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
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

        if submission.status != "submitted" && submission.status != "returned" && submission.status != "graded" {
            return Err(AppError::BadRequest(format!(
                "Cannot grade a submission with status '{}'",
                submission.status
            )));
        }

        if request.score < 0 || request.score > assignment.total_points {
            return Err(AppError::BadRequest(format!(
                "Score must be between 0 and {}",
                assignment.total_points
            )));
        }

        if let Some(ref feedback) = request.feedback {
            if feedback.len() > 5000 {
                return Err(AppError::BadRequest(
                    "Feedback must be at most 5000 characters".to_string(),
                ));
            }
        }

        let graded = self
            .assignment_repo
            .grade_submission(submission_id, request.score, request.feedback, Some(teacher_id))
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_graded",
                Some(format!(
                    "Graded assignment '{}' - score: {}/{}",
                    assignment.title, request.score, assignment.total_points
                )),
            )
            .await;

        let student_name = self
            .assignment_repo
            .find_student_name(graded.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(graded, student_name, files))
    }

    pub async fn return_submission(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssignmentSubmissionResponse> {
        let submission = self
            .assignment_repo
            .find_submission_by_id(submission_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assignment = self
            .assignment_repo
            .find_by_id(submission.assignment_id)
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

        if submission.status != "submitted" {
            return Err(AppError::BadRequest(
                "Can only return submitted submissions".to_string(),
            ));
        }

        let returned = self
            .assignment_repo
            .return_submission(submission_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "assignment_returned",
                Some(format!(
                    "Returned assignment '{}' for revision",
                    assignment.title
                )),
            )
            .await;

        let student_name = self
            .assignment_repo
            .find_student_name(returned.student_id)
            .await?;
        let files = self
            .assignment_repo
            .find_files_by_submission(submission_id)
            .await?;

        Ok(self.build_submission_response(returned, student_name, files))
    }

    pub async fn get_student_assignment_submissions(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<StudentAssignmentSubmissionsResponse> {
        // 1. Auth check
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Teacher access required".to_string()));
        }

        // 2. Get all published assignments for this class
        let assignments = self.assignment_repo.find_published_by_class_id(class_id).await?;

        // 3. Get student name once
        let student_name = self.assignment_repo.find_student_name(student_id).await?;

        // 4. Look up student submission for each
        let mut items = Vec::new();
        for assignment in assignments {
            if let Some(sub) = self.assignment_repo
                .find_student_submission(assignment.id, student_id).await? {
                items.push(StudentAssignmentSubmissionItem {
                    assignment_id: assignment.id,
                    id: sub.id,
                    student_id: sub.student_id,
                    student_name: student_name.clone(),
                    status: sub.status.clone(),
                    submitted_at: sub.submitted_at.map(|dt| dt.to_string()),
                    is_late: sub.is_late,
                    score: sub.points,
                });
            }
        }

        Ok(StudentAssignmentSubmissionsResponse { submissions: items })
    }
}