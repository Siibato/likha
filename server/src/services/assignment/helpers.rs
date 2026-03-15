use crate::schema::assignment_schema::*;

impl super::AssignmentService {
    pub fn build_submission_response(
        &self,
        submission: ::entity::assignment_submissions::Model,
        student_name: String,
        files: Vec<::entity::submission_files::Model>,
    ) -> AssignmentSubmissionResponse {
        let file_responses: Vec<FileMetadataResponse> = files
            .into_iter()
            .map(|f| FileMetadataResponse {
                id: f.id,
                file_name: f.file_name,
                file_type: f.file_type,
                file_size: f.file_size,
                uploaded_at: f.uploaded_at.to_string(),
            })
            .collect();

        AssignmentSubmissionResponse {
            id: submission.id,
            assignment_id: submission.assignment_id,
            student_id: submission.student_id,
            student_name,
            status: submission.status,
            text_content: submission.text_content,
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            is_late: submission.is_late,
            score: submission.points,
            feedback: submission.feedback,
            graded_at: submission.graded_at.map(|dt| dt.to_string()),
            files: file_responses,
            created_at: submission.created_at.to_string(),
            updated_at: submission.updated_at.to_string(),
        }
    }
}