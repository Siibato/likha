use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{assignment_submissions, assignments_hw, submission_files, users};
use crate::utils::{AppError, AppResult};

pub struct AssignmentRepository {
    db: DatabaseConnection,
}

impl AssignmentRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ===== ASSIGNMENTS =====

    pub async fn create_assignment(
        &self,
        class_id: Uuid,
        title: String,
        instructions: String,
        total_points: i32,
        submission_type: String,
        allowed_file_types: Option<String>,
        max_file_size_mb: Option<i32>,
        due_at: chrono::NaiveDateTime,
    ) -> AppResult<assignments_hw::Model> {
        let assignment = assignments_hw::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            title: Set(title),
            instructions: Set(instructions),
            total_points: Set(total_points),
            submission_type: Set(submission_type),
            allowed_file_types: Set(allowed_file_types),
            max_file_size_mb: Set(max_file_size_mb),
            due_at: Set(due_at),
            is_published: Set(false),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
        };

        assignment
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create assignment: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<assignments_hw::Model>> {
        assignments_hw::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assignments_hw::Model>> {
        assignments_hw::Entity::find()
            .filter(assignments_hw::Column::ClassId.eq(class_id))
            .order_by_desc(assignments_hw::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_published_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<assignments_hw::Model>> {
        assignments_hw::Entity::find()
            .filter(assignments_hw::Column::ClassId.eq(class_id))
            .filter(assignments_hw::Column::IsPublished.eq(true))
            .order_by_desc(assignments_hw::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_assignment(
        &self,
        id: Uuid,
        title: Option<String>,
        instructions: Option<String>,
        total_points: Option<i32>,
        submission_type: Option<String>,
        allowed_file_types: Option<Option<String>>,
        max_file_size_mb: Option<Option<i32>>,
        due_at: Option<chrono::NaiveDateTime>,
    ) -> AppResult<assignments_hw::Model> {
        let mut assignment: assignments_hw::ActiveModel = assignments_hw::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?
            .into();

        if let Some(title) = title {
            assignment.title = Set(title);
        }
        if let Some(instructions) = instructions {
            assignment.instructions = Set(instructions);
        }
        if let Some(total_points) = total_points {
            assignment.total_points = Set(total_points);
        }
        if let Some(submission_type) = submission_type {
            assignment.submission_type = Set(submission_type);
        }
        if let Some(allowed) = allowed_file_types {
            assignment.allowed_file_types = Set(allowed);
        }
        if let Some(max_size) = max_file_size_mb {
            assignment.max_file_size_mb = Set(max_size);
        }
        if let Some(due) = due_at {
            assignment.due_at = Set(due);
        }
        assignment.updated_at = Set(Utc::now().naive_utc());

        assignment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update assignment: {}", e)))
    }

    pub async fn delete_assignment(&self, id: Uuid) -> AppResult<()> {
        assignments_hw::Entity::delete_by_id(id)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete assignment: {}", e)))?;
        Ok(())
    }

    pub async fn publish_assignment(&self, id: Uuid) -> AppResult<assignments_hw::Model> {
        let mut assignment: assignments_hw::ActiveModel = assignments_hw::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Assignment not found".to_string()))?
            .into();

        assignment.is_published = Set(true);
        assignment.updated_at = Set(Utc::now().naive_utc());

        assignment
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to publish assignment: {}", e)))
    }

    // ===== SUBMISSIONS =====

    pub async fn create_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<assignment_submissions::Model> {
        let submission = assignment_submissions::ActiveModel {
            id: Set(Uuid::new_v4()),
            assignment_id: Set(assignment_id),
            student_id: Set(student_id),
            status: Set("draft".to_string()),
            text_content: Set(None),
            submitted_at: Set(None),
            is_late: Set(false),
            score: Set(None),
            feedback: Set(None),
            graded_at: Set(None),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
        };

        submission
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create submission: {}", e)))
    }

    pub async fn find_submission_by_id(&self, id: Uuid) -> AppResult<Option<assignment_submissions::Model>> {
        assignment_submissions::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_submissions_by_assignment(
        &self,
        assignment_id: Uuid,
    ) -> AppResult<Vec<(assignment_submissions::Model, Option<users::Model>)>> {
        assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
            .find_also_related(users::Entity)
            .order_by_asc(assignment_submissions::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_student_submission(
        &self,
        assignment_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Option<assignment_submissions::Model>> {
        assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
            .filter(assignment_submissions::Column::StudentId.eq(student_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_submission_text(
        &self,
        id: Uuid,
        text_content: Option<String>,
    ) -> AppResult<assignment_submissions::Model> {
        let mut submission: assignment_submissions::ActiveModel =
            assignment_submissions::Entity::find_by_id(id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.text_content = Set(text_content);
        submission.updated_at = Set(Utc::now().naive_utc());

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update submission: {}", e)))
    }

    pub async fn update_submission_status(
        &self,
        id: Uuid,
        status: &str,
        is_late: Option<bool>,
    ) -> AppResult<assignment_submissions::Model> {
        let mut submission: assignment_submissions::ActiveModel =
            assignment_submissions::Entity::find_by_id(id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.status = Set(status.to_string());
        if status == "submitted" {
            submission.submitted_at = Set(Some(Utc::now().naive_utc()));
        }
        if let Some(late) = is_late {
            submission.is_late = Set(late);
        }
        submission.updated_at = Set(Utc::now().naive_utc());

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update submission status: {}", e)))
    }

    pub async fn grade_submission(
        &self,
        id: Uuid,
        score: i32,
        feedback: Option<String>,
    ) -> AppResult<assignment_submissions::Model> {
        let mut submission: assignment_submissions::ActiveModel =
            assignment_submissions::Entity::find_by_id(id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.status = Set("graded".to_string());
        submission.score = Set(Some(score));
        submission.feedback = Set(feedback);
        submission.graded_at = Set(Some(Utc::now().naive_utc()));
        submission.updated_at = Set(Utc::now().naive_utc());

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to grade submission: {}", e)))
    }

    pub async fn return_submission(&self, id: Uuid) -> AppResult<assignment_submissions::Model> {
        let mut submission: assignment_submissions::ActiveModel =
            assignment_submissions::Entity::find_by_id(id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
                .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?
                .into();

        submission.status = Set("returned".to_string());
        submission.updated_at = Set(Utc::now().naive_utc());

        submission
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to return submission: {}", e)))
    }

    pub async fn count_submissions_by_assignment(&self, assignment_id: Uuid) -> AppResult<usize> {
        let count = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
            .filter(assignment_submissions::Column::Status.ne("draft"))
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        Ok(count as usize)
    }

    pub async fn count_graded_by_assignment(&self, assignment_id: Uuid) -> AppResult<usize> {
        let count = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::AssignmentId.eq(assignment_id))
            .filter(assignment_submissions::Column::Status.eq("graded"))
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        Ok(count as usize)
    }

    // ===== FILES =====

    pub async fn save_file(
        &self,
        submission_id: Uuid,
        file_name: String,
        file_type: String,
        file_size: i64,
        file_data: Vec<u8>,
    ) -> AppResult<submission_files::Model> {
        let file = submission_files::ActiveModel {
            id: Set(Uuid::new_v4()),
            submission_id: Set(submission_id),
            file_name: Set(file_name),
            file_type: Set(file_type),
            file_size: Set(file_size),
            file_data: Set(file_data),
            uploaded_at: Set(Utc::now().naive_utc()),
        };

        file.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to save file: {}", e)))
    }

    pub async fn find_file_by_id(&self, id: Uuid) -> AppResult<Option<submission_files::Model>> {
        submission_files::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_files_by_submission(
        &self,
        submission_id: Uuid,
    ) -> AppResult<Vec<submission_files::Model>> {
        submission_files::Entity::find()
            .filter(submission_files::Column::SubmissionId.eq(submission_id))
            .order_by_asc(submission_files::Column::UploadedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn delete_file(&self, id: Uuid) -> AppResult<()> {
        submission_files::Entity::delete_by_id(id)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete file: {}", e)))?;
        Ok(())
    }

    pub async fn find_student_name(&self, student_id: Uuid) -> AppResult<String> {
        let user = users::Entity::find_by_id(student_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
        Ok(user.full_name)
    }

    pub async fn find_all(&self) -> AppResult<Vec<assignments_hw::Model>> {
        assignments_hw::Entity::find()
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }
}
