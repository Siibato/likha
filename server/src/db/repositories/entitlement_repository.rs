use chrono::NaiveDateTime;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{classes, class_enrollments, users};
use crate::utils::{AppError, AppResult};

/// Verifies user authorization and scopes queries by entitlement
pub struct EntitlementRepository {
    db: DatabaseConnection,
}

impl EntitlementRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Get all classes user is enrolled in (student) or teaches (teacher)
    /// Admin can access all classes
    pub async fn get_user_accessible_classes(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<Vec<Uuid>> {
        match user_role {
            "student" => {
                // Students can see classes they're enrolled in
                let enrollments = class_enrollments::Entity::find()
                    .filter(class_enrollments::Column::StudentId.eq(user_id))
                    .filter(class_enrollments::Column::RemovedAt.is_null())
                    .all(&self.db)
                    .await
                    .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

                Ok(enrollments.iter().map(|e| e.class_id).collect())
            }
            "teacher" => {
                // Teachers can see classes they teach
                let classes = classes::Entity::find()
                    .filter(classes::Column::TeacherId.eq(user_id))
                    .filter(classes::Column::IsArchived.eq(false))
                    .all(&self.db)
                    .await
                    .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

                Ok(classes.iter().map(|c| c.id).collect())
            }
            "admin" => {
                // Admins can see all classes
                let classes = classes::Entity::find().all(&self.db).await.map_err(|e| {
                    AppError::InternalServerError(format!("Database error: {}", e))
                })?;

                Ok(classes.iter().map(|c| c.id).collect())
            }
            _ => Err(AppError::BadRequest(format!("Invalid role: {}", user_role))),
        }
    }

    /// Check if user is enrolled in a specific class (for student)
    pub async fn is_student_in_class(
        &self,
        student_id: Uuid,
        class_id: Uuid,
    ) -> AppResult<bool> {
        let enrollment = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::StudentId.eq(student_id))
            .filter(class_enrollments::Column::ClassId.eq(class_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(enrollment.is_some())
    }

    /// Check if user teaches a specific class
    pub async fn is_teacher_of_class(
        &self,
        teacher_id: Uuid,
        class_id: Uuid,
    ) -> AppResult<bool> {
        let class = classes::Entity::find_by_id(class_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(class.map(|c| c.teacher_id == teacher_id).unwrap_or(false))
    }

    /// Verify user can perform an action on an entity
    /// Returns error if not authorized
    pub async fn assert_can_modify_class(
        &self,
        user_id: Uuid,
        user_role: &str,
        class_id: Uuid,
    ) -> AppResult<()> {
        if user_role == "admin" {
            return Ok(());
        }

        if user_role != "teacher" {
            return Err(AppError::Forbidden(
                "Only teachers and admins can modify classes".to_string(),
            ));
        }

        if !self.is_teacher_of_class(user_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only modify your own classes".to_string(),
            ));
        }

        Ok(())
    }

    /// Verify student can submit for an assessment/assignment
    pub async fn assert_can_submit_assessment(
        &self,
        student_id: Uuid,
        class_id: Uuid,
    ) -> AppResult<()> {
        if !self.is_student_in_class(student_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You are not enrolled in this class".to_string(),
            ));
        }

        Ok(())
    }

    /// Get all students in a class
    pub async fn get_class_students(&self, class_id: Uuid) -> AppResult<Vec<Uuid>> {
        let enrollments = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::ClassId.eq(class_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(enrollments.iter().map(|e| e.student_id).collect())
    }
}
