use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::{json, Value};
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{
    classes, class_enrollments, assessments, assessment_questions, assessment_submissions,
    assignments_hw, assignment_submissions, learning_materials, activity_logs,
};

/// Record entry in the manifest (id + updated_at + deleted flag)
#[derive(Debug, Clone)]
pub struct ManifestEntry {
    pub id: Uuid,
    pub updated_at: NaiveDateTime,
    pub deleted: bool,
}

/// Get records with pagination
#[derive(Debug, Clone)]
pub struct PaginatedRecords {
    pub records: Vec<Value>,
    pub has_more: bool,
}

/// Repository for building and querying manifests
#[derive(Clone)]
pub struct ManifestRepository {
    db: DatabaseConnection,
}

impl ManifestRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Get manifest entries for classes (with timestamps for delta sync)
    pub async fn get_classes_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = classes::Entity::find()
            .filter(classes::Column::Id.is_in(class_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.updated_at,
                deleted: false, // Classes don't have soft delete column yet
            })
            .collect())
    }

    /// Get manifest entries for enrollments
    pub async fn get_enrollments_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::ClassId.is_in(class_ids))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.enrolled_at,
                deleted: r.removed_at.is_some(),
            })
            .collect())
    }

    /// Get manifest entries for assessments in classes
    pub async fn get_assessments_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assessments::Entity::find()
            .filter(assessments::Column::ClassId.is_in(class_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.updated_at,
                deleted: r.deleted_at.is_some(),
            })
            .collect())
    }

    /// Get manifest entries for assessment questions
    pub async fn get_questions_manifest(
        &self,
        assessment_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assessment_questions::Entity::find()
            .filter(assessment_questions::Column::AssessmentId.is_in(assessment_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.updated_at,
                deleted: r.deleted_at.is_some(),
            })
            .collect())
    }

    /// Get manifest entries for assessment submissions (user-specific)
    pub async fn get_assessment_submissions_manifest(
        &self,
        user_id: Uuid,
        assessment_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::StudentId.eq(user_id))
            .filter(assessment_submissions::Column::AssessmentId.is_in(assessment_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.created_at, // Use created_at since updated_at doesn't exist
                deleted: false,
            })
            .collect())
    }

    /// Get manifest entries for assignments
    pub async fn get_assignments_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assignments_hw::Entity::find()
            .filter(assignments_hw::Column::ClassId.is_in(class_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.updated_at,
                deleted: r.deleted_at.is_some(),
            })
            .collect())
    }

    /// Get manifest entries for assignment submissions
    pub async fn get_assignment_submissions_manifest(
        &self,
        user_id: Uuid,
        assignment_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::StudentId.eq(user_id))
            .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.updated_at,
                deleted: false,
            })
            .collect())
    }

    /// Get manifest entries for learning materials
    pub async fn get_materials_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = learning_materials::Entity::find()
            .filter(learning_materials::Column::ClassId.is_in(class_ids))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.updated_at,
                deleted: r.deleted_at.is_some(),
            })
            .collect())
    }

    /// Get full paginated records for a set of IDs
    /// limit: max records per page (capped at 500)
    pub async fn get_classes_paginated(
        &self,
        class_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = classes::Entity::find()
            .filter(classes::Column::Id.is_in(class_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "title": r.title,
                    "description": r.description,
                    "teacher_id": r.teacher_id.to_string(),
                    "is_archived": r.is_archived,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for assessments
    pub async fn get_assessments_paginated(
        &self,
        assessment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = assessments::Entity::find()
            .filter(assessments::Column::Id.is_in(assessment_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "title": r.title,
                    "description": r.description,
                    "time_limit_minutes": r.time_limit_minutes,
                    "is_published": r.is_published,
                    "results_released": r.results_released,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for assignments
    pub async fn get_assignments_paginated(
        &self,
        assignment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = assignments_hw::Entity::find()
            .filter(assignments_hw::Column::Id.is_in(assignment_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "title": r.title,
                    "instructions": r.instructions,
                    "total_points": r.total_points,
                    "due_at": r.due_at.to_string(),
                    "is_published": r.is_published,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for learning materials
    pub async fn get_materials_paginated(
        &self,
        material_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = learning_materials::Entity::find()
            .filter(learning_materials::Column::Id.is_in(material_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "title": r.title,
                    "description": r.description,
                    "content_text": r.content_text,
                    "order_index": r.order_index,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for class enrollments
    pub async fn get_enrollments_paginated(
        &self,
        enrollment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::Id.is_in(enrollment_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "student_id": r.student_id.to_string(),
                    "enrolled_at": r.enrolled_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for assessment questions
    pub async fn get_questions_paginated(
        &self,
        question_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = assessment_questions::Entity::find()
            .filter(assessment_questions::Column::Id.is_in(question_ids))
            .filter(assessment_questions::Column::DeletedAt.is_null())
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "assessment_id": r.assessment_id.to_string(),
                    "question_type": r.question_type,
                    "question_text": r.question_text,
                    "points": r.points,
                    "order_index": r.order_index,
                    "is_multi_select": r.is_multi_select,
                    "updated_at": r.updated_at.to_string(),
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for assessment submissions (user-specific)
    pub async fn get_assessment_submissions_paginated(
        &self,
        user_id: Uuid,
        submission_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::StudentId.eq(user_id))
            .filter(assessment_submissions::Column::Id.is_in(submission_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "assessment_id": r.assessment_id.to_string(),
                    "student_id": r.student_id.to_string(),
                    "started_at": r.created_at.to_string(),
                    "submitted_at": r.submitted_at.map(|d| d.to_string()),
                    "auto_score": r.auto_score,
                    "final_score": r.final_score,
                    "is_submitted": r.is_submitted,
                    "updated_at": r.updated_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get full paginated records for assignment submissions (user-specific)
    pub async fn get_assignment_submissions_paginated(
        &self,
        user_id: Uuid,
        submission_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::StudentId.eq(user_id))
            .filter(assignment_submissions::Column::Id.is_in(submission_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "assignment_id": r.assignment_id.to_string(),
                    "student_id": r.student_id.to_string(),
                    "status": r.status,
                    "submitted_at": r.submitted_at.map(|d| d.to_string()),
                    "score": r.score,
                    "updated_at": r.updated_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }

    /// Get manifest for activity logs - admin can see all, users see their own
    pub async fn get_activity_logs_manifest(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = if user_role == "admin" {
            // Admins see all activity logs
            activity_logs::Entity::find()
                .all(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        } else {
            // Regular users see only their own activity logs
            activity_logs::Entity::find()
                .filter(activity_logs::Column::UserId.eq(user_id))
                .all(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        };

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.created_at,
                deleted: false, // Activity logs are never soft-deleted
            })
            .collect())
    }

    /// Get full paginated records for activity logs
    pub async fn get_activity_logs_paginated(
        &self,
        activity_log_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let effective_limit = std::cmp::min(limit, 500) as u64;

        let records = activity_logs::Entity::find()
            .filter(activity_logs::Column::Id.is_in(activity_log_ids))
            .limit(effective_limit + 1)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "user_id": r.user_id.to_string(),
                    "action": r.action,
                    "performed_by": r.performed_by.map(|id| id.to_string()),
                    "details": r.details,
                    "created_at": r.created_at.to_string(),
                })
            })
            .collect();

        Ok(PaginatedRecords { records, has_more })
    }
}
