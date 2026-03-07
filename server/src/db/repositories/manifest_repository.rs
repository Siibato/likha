use chrono::NaiveDateTime;
use sea_orm::*;
use serde_json::{json, Value};
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use ::entity::{
    classes, class_participants, assessments, assessment_questions, assessment_submissions,
    assignments_hw, assignment_submissions, learning_materials, activity_logs, users,
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

    /// Build a map of class_id -> (teacher_id, teacher_username, teacher_full_name)
    async fn build_teacher_map(
        &self,
        class_ids: &[Uuid],
    ) -> AppResult<std::collections::HashMap<Uuid, (Uuid, String, String)>> {
        // Fetch all teacher participants for these classes
        let participants = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.is_in(class_ids.to_vec()))
            .filter(class_participants::Column::Role.eq("teacher"))
            .filter(class_participants::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let mut map = std::collections::HashMap::new();

        for participant in participants {
            // Fetch the user details for this participant
            if let Ok(Some(user)) = users::Entity::find_by_id(participant.user_id)
                .one(&self.db)
                .await
            {
                map.insert(
                    participant.class_id,
                    (user.id, user.username.clone(), user.full_name.clone()),
                );
            }
        }

        Ok(map)
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

    /// Get manifest entries for enrollments (class participants with student role)
    /// For students, only returns their own enrollment records.
    /// For teachers/admins, returns all student enrollments in their classes.
    pub async fn get_enrollments_manifest(
        &self,
        class_ids: Vec<Uuid>,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<Vec<ManifestEntry>> {
        let mut query = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.is_in(class_ids))
            .filter(class_participants::Column::Role.eq("student"))
            .filter(class_participants::Column::RemovedAt.is_null());

        if user_role == "student" {
            query = query.filter(class_participants::Column::UserId.eq(user_id));
        }

        let records = query
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(records
            .into_iter()
            .map(|r| ManifestEntry {
                id: r.id,
                updated_at: r.joined_at,
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
                updated_at: r.updated_at,
                deleted: false,
            })
            .collect())
    }

    /// Get manifest entries for assessments (published only)
    pub async fn get_published_assessments_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assessments::Entity::find()
            .filter(assessments::Column::ClassId.is_in(class_ids))
            .filter(assessments::Column::IsPublished.eq(true))
            .filter(assessments::Column::DeletedAt.is_null())
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

    /// Get manifest entries for assignments (published only)
    pub async fn get_published_assignments_manifest(
        &self,
        class_ids: Vec<Uuid>,
    ) -> AppResult<Vec<ManifestEntry>> {
        let records = assignments_hw::Entity::find()
            .filter(assignments_hw::Column::ClassId.is_in(class_ids))
            .filter(assignments_hw::Column::IsPublished.eq(true))
            .filter(assignments_hw::Column::DeletedAt.is_null())
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
        if class_ids.is_empty() {
            // No classes, return empty result
            return Ok(PaginatedRecords {
                records: vec![],
                has_more: false,
            });
        }

        let teacher_map = self.build_teacher_map(&class_ids).await?;

        let query = classes::Entity::find()
            .filter(classes::Column::Id.is_in(class_ids));
        Self::paginate_query(&self.db, query, limit, move |r| {
            let (teacher_id, teacher_username, teacher_full_name) = teacher_map
                .get(&r.id)
                .map(|t| (t.0.to_string(), t.1.clone(), t.2.clone()))
                .unwrap_or_else(|| ("".to_string(), "".to_string(), "".to_string()));

            json!({
                "id": r.id.to_string(),
                "title": r.title,
                "description": r.description,
                "is_archived": r.is_archived,
                "teacher_id": teacher_id,
                "teacher_username": teacher_username,
                "teacher_full_name": teacher_full_name,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
                "student_count": 0,
            })
        })
        .await
    }

    /// Get full paginated records for assessments
    pub async fn get_assessments_paginated(
        &self,
        assessment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assessments::Entity::find()
            .filter(assessments::Column::Id.is_in(assessment_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "class_id": r.class_id.to_string(),
                "title": r.title,
                "description": r.description,
                "time_limit_minutes": r.time_limit_minutes,
                "open_at": r.open_at.to_string(),
                "close_at": r.close_at.to_string(),
                "show_results_immediately": r.show_results_immediately,
                "is_published": r.is_published,
                "results_released": r.results_released,
                "total_points": r.total_points,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get full paginated records for assignments
    pub async fn get_assignments_paginated(
        &self,
        assignment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assignments_hw::Entity::find()
            .filter(assignments_hw::Column::Id.is_in(assignment_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "class_id": r.class_id.to_string(),
                "title": r.title,
                "instructions": r.instructions,
                "total_points": r.total_points,
                "submission_type": r.submission_type,
                "allowed_file_types": r.allowed_file_types,
                "max_file_size_mb": r.max_file_size_mb,
                "due_at": r.due_at.to_string(),
                "is_published": r.is_published,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get full paginated records for learning materials
    pub async fn get_materials_paginated(
        &self,
        material_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = learning_materials::Entity::find()
            .filter(learning_materials::Column::Id.is_in(material_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
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
        .await
    }

    /// Get full paginated records for class enrollments (class participants with student role)
    pub async fn get_enrollments_paginated(
        &self,
        enrollment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = class_participants::Entity::find()
            .filter(class_participants::Column::Id.is_in(enrollment_ids))
            .filter(class_participants::Column::Role.eq("student"));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "class_id": r.class_id.to_string(),
                "user_id": r.user_id.to_string(),
                "student_id": r.user_id.to_string(),
                "joined_at": r.joined_at.to_string(),
                "enrolled_at": r.joined_at.to_string(),
            })
        })
        .await
    }

    /// Get full paginated records for assessment questions
    pub async fn get_questions_paginated(
        &self,
        question_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assessment_questions::Entity::find()
            .filter(assessment_questions::Column::Id.is_in(question_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
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
        .await
    }

    /// Get full paginated records for assessment submissions (user-specific)
    pub async fn get_assessment_submissions_paginated(
        &self,
        user_id: Uuid,
        submission_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::StudentId.eq(user_id))
            .filter(assessment_submissions::Column::Id.is_in(submission_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "assessment_id": r.assessment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "started_at": r.started_at.to_string(),
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "auto_score": r.auto_score,
                "final_score": r.final_score,
                "is_submitted": r.is_submitted,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get full paginated records for assignment submissions (user-specific)
    pub async fn get_assignment_submissions_paginated(
        &self,
        user_id: Uuid,
        submission_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::StudentId.eq(user_id))
            .filter(assignment_submissions::Column::Id.is_in(submission_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "assignment_id": r.assignment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "status": r.status,
                "text_content": r.text_content,
                "is_late": r.is_late,
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "score": r.score,
                "feedback": r.feedback,
                "graded_at": r.graded_at.map(|d| d.to_string()),
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
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
        let query = activity_logs::Entity::find()
            .filter(activity_logs::Column::Id.is_in(activity_log_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "user_id": r.user_id.to_string(),
                "action": r.action,
                "performed_by": r.performed_by.map(|id| id.to_string()),
                "details": r.details,
                "created_at": r.created_at.to_string(),
            })
        })
        .await
    }

    /// Get classes that have been updated since a given time
    pub async fn get_classes_since(
        &self,
        class_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        if class_ids.is_empty() {
            return Ok(vec![]);
        }

        let records = classes::Entity::find()
            .filter(classes::Column::Id.is_in(class_ids.clone()))
            .filter(classes::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let teacher_map = self.build_teacher_map(&class_ids).await?;

        let records: Vec<Value> = records
            .into_iter()
            .map(move |r| {
                let (teacher_id, teacher_username, teacher_full_name) = teacher_map
                    .get(&r.id)
                    .map(|t| (t.0.to_string(), t.1.clone(), t.2.clone()))
                    .unwrap_or_else(|| ("".to_string(), "".to_string(), "".to_string()));

                json!({
                    "id": r.id.to_string(),
                    "title": r.title,
                    "description": r.description,
                    "is_archived": r.is_archived,
                    "teacher_id": teacher_id,
                    "teacher_username": teacher_username,
                    "teacher_full_name": teacher_full_name,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get assessments that have been updated since a given time
    pub async fn get_assessments_since(
        &self,
        assessment_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = assessments::Entity::find()
            .filter(assessments::Column::Id.is_in(assessment_ids))
            .filter(assessments::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "title": r.title,
                    "description": r.description,
                    "time_limit_minutes": r.time_limit_minutes,
                    "open_at": r.open_at.to_string(),
                    "close_at": r.close_at.to_string(),
                    "show_results_immediately": r.show_results_immediately,
                    "is_published": r.is_published,
                    "results_released": r.results_released,
                    "total_points": r.total_points,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get assignments that have been updated since a given time
    pub async fn get_assignments_since(
        &self,
        assignment_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = assignments_hw::Entity::find()
            .filter(assignments_hw::Column::Id.is_in(assignment_ids))
            .filter(assignments_hw::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "title": r.title,
                    "instructions": r.instructions,
                    "total_points": r.total_points,
                    "submission_type": r.submission_type,
                    "allowed_file_types": r.allowed_file_types,
                    "max_file_size_mb": r.max_file_size_mb,
                    "due_at": r.due_at.to_string(),
                    "is_published": r.is_published,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get learning materials that have been updated since a given time
    pub async fn get_materials_since(
        &self,
        material_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = learning_materials::Entity::find()
            .filter(learning_materials::Column::Id.is_in(material_ids))
            .filter(learning_materials::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
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
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get class enrollments that have been updated since a given time
    pub async fn get_enrollments_since(
        &self,
        enrollment_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = class_participants::Entity::find()
            .filter(class_participants::Column::Id.is_in(enrollment_ids))
            .filter(class_participants::Column::Role.eq("student"))
            .filter(class_participants::Column::JoinedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "class_id": r.class_id.to_string(),
                    "user_id": r.user_id.to_string(),
                    "student_id": r.user_id.to_string(),
                    "joined_at": r.joined_at.to_string(),
                    "enrolled_at": r.joined_at.to_string(),
                    "removed_at": r.removed_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get assessment questions that have been updated since a given time
    pub async fn get_questions_since(
        &self,
        question_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = assessment_questions::Entity::find()
            .filter(assessment_questions::Column::Id.is_in(question_ids))
            .filter(assessment_questions::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
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

        Ok(records)
    }

    /// Get assessment submissions that have been updated since a given time
    pub async fn get_assessment_submissions_since(
        &self,
        user_id: Uuid,
        submission_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::StudentId.eq(user_id))
            .filter(assessment_submissions::Column::Id.is_in(submission_ids))
            .filter(assessment_submissions::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "assessment_id": r.assessment_id.to_string(),
                    "student_id": r.student_id.to_string(),
                    "started_at": r.started_at.to_string(),
                    "submitted_at": r.submitted_at.map(|d| d.to_string()),
                    "auto_score": r.auto_score,
                    "final_score": r.final_score,
                    "is_submitted": r.is_submitted,
                    "created_at": r.created_at.to_string(),
                    "updated_at": r.updated_at.to_string(),
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get assignment submissions that have been updated since a given time
    pub async fn get_assignment_submissions_since(
        &self,
        user_id: Uuid,
        submission_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::StudentId.eq(user_id))
            .filter(assignment_submissions::Column::Id.is_in(submission_ids))
            .filter(assignment_submissions::Column::UpdatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
            .map(|r| {
                json!({
                    "id": r.id.to_string(),
                    "assignment_id": r.assignment_id.to_string(),
                    "student_id": r.student_id.to_string(),
                    "status": r.status,
                    "submitted_at": r.submitted_at.map(|d| d.to_string()),
                    "score": r.score,
                    "updated_at": r.updated_at.to_string(),
                    "deleted_at": r.deleted_at.map(|d| d.to_string()),
                })
            })
            .collect();

        Ok(records)
    }

    /// Get activity logs that have been created since a given time
    pub async fn get_activity_logs_since(
        &self,
        activity_log_ids: Vec<Uuid>,
        since: NaiveDateTime,
    ) -> AppResult<Vec<Value>> {
        let records = activity_logs::Entity::find()
            .filter(activity_logs::Column::Id.is_in(activity_log_ids))
            .filter(activity_logs::Column::CreatedAt.gt(since))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let records: Vec<Value> = records
            .into_iter()
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

        Ok(records)
    }

    /// Get assessment submissions for a student filtered by assessment IDs (for batch full sync)
    /// Used when a student requests full sync for specific classes (assessments)
    pub async fn get_student_submissions_for_assessments(
        &self,
        user_id: Uuid,
        assessment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::StudentId.eq(user_id))
            .filter(assessment_submissions::Column::AssessmentId.is_in(assessment_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "assessment_id": r.assessment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "started_at": r.started_at.to_string(),
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "auto_score": r.auto_score,
                "final_score": r.final_score,
                "is_submitted": r.is_submitted,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get assignment submissions for a student filtered by assignment IDs (for batch full sync)
    /// Used when a student requests full sync for specific classes (assignments)
    pub async fn get_student_assignment_submissions_for_assignments(
        &self,
        user_id: Uuid,
        assignment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::StudentId.eq(user_id))
            .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "assignment_id": r.assignment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "status": r.status,
                "text_content": r.text_content,
                "is_late": r.is_late,
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "score": r.score,
                "feedback": r.feedback,
                "graded_at": r.graded_at.map(|d| d.to_string()),
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get ALL assessment submissions for given assessments (not filtered by student_id)
    /// Used by teachers/admins to fetch submissions for all students
    pub async fn get_all_assessment_submissions_for_assessments(
        &self,
        assessment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assessment_submissions::Entity::find()
            .filter(assessment_submissions::Column::AssessmentId.is_in(assessment_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "assessment_id": r.assessment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "started_at": r.started_at.to_string(),
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "auto_score": r.auto_score,
                "final_score": r.final_score,
                "is_submitted": r.is_submitted,
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get ALL assignment submissions for given assignments (not filtered by student_id)
    /// Used by teachers/admins to fetch submissions for all students
    pub async fn get_all_assignment_submissions_for_assignments(
        &self,
        assignment_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = assignment_submissions::Entity::find()
            .filter(assignment_submissions::Column::AssignmentId.is_in(assignment_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            json!({
                "id": r.id.to_string(),
                "assignment_id": r.assignment_id.to_string(),
                "student_id": r.student_id.to_string(),
                "status": r.status,
                "text_content": r.text_content,
                "is_late": r.is_late,
                "submitted_at": r.submitted_at.map(|d| d.to_string()),
                "score": r.score,
                "feedback": r.feedback,
                "graded_at": r.graded_at.map(|d| d.to_string()),
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
                "deleted_at": r.deleted_at.map(|d| d.to_string()),
            })
        })
        .await
    }

    /// Get users by IDs with full profile data
    pub async fn get_users_paginated(
        &self,
        user_ids: Vec<Uuid>,
        limit: i64,
    ) -> AppResult<PaginatedRecords> {
        let query = users::Entity::find()
            .filter(users::Column::Id.is_in(user_ids));
        Self::paginate_query(&self.db, query, limit, |r| {
            let is_active = r.account_status != "locked" && r.account_status != "deactivated";
            json!({
                "id": r.id.to_string(),
                "username": r.username,
                "full_name": r.full_name,
                "role": r.role,
                "account_status": r.account_status,
                "is_active": is_active,
                "activated_at": r.activated_at.map(|d| d.to_string()),
                "created_at": r.created_at.to_string(),
                "updated_at": r.updated_at.to_string(),
            })
        })
        .await
    }

    /// Generic pagination helper — handles limit capping, has_more detection, and record collection
    async fn paginate_query<E, F>(
        db: &DatabaseConnection,
        query: Select<E>,
        limit: i64,
        mapper: F,
    ) -> AppResult<PaginatedRecords>
    where
        E: EntityTrait,
        E::Model: Send + Sync,
        F: Fn(E::Model) -> Value,
    {
        let effective_limit = std::cmp::min(limit, 500) as u64;
        let records = query
            .limit(effective_limit + 1)
            .all(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        let has_more = records.len() > effective_limit as usize;
        let records: Vec<Value> = records
            .into_iter()
            .take(effective_limit as usize)
            .map(mapper)
            .collect();
        Ok(PaginatedRecords { records, has_more })
    }
}
