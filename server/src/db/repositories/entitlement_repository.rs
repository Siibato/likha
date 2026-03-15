use sea_orm::*;
use uuid::Uuid;

use ::entity::{classes, class_participants, users};
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
            "student" | "teacher" => {
                // Students and teachers can see their enrolled classes
                let participants = class_participants::Entity::find()
                    .filter(class_participants::Column::UserId.eq(user_id))
                    .filter(class_participants::Column::RemovedAt.is_null())
                    .all(&self.db)
                    .await
                    .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

                Ok(participants.iter().map(|p| p.class_id).collect())
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
        let participant = class_participants::Entity::find()
            .filter(class_participants::Column::UserId.eq(student_id))
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Verify the user is actually a student
        if let Some(p) = participant {
            if let Some(user) = users::Entity::find_by_id(student_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                return Ok(user.role == "student");
            }
        }
        Ok(false)
    }

    /// Check if user teaches a specific class
    pub async fn is_teacher_of_class(
        &self,
        teacher_id: Uuid,
        class_id: Uuid,
    ) -> AppResult<bool> {
        let participant = class_participants::Entity::find()
            .filter(class_participants::Column::UserId.eq(teacher_id))
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Verify the user is actually a teacher
        if let Some(p) = participant {
            if let Some(user) = users::Entity::find_by_id(teacher_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                return Ok(user.role == "teacher");
            }
        }
        Ok(false)
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
        let participants = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Filter to only students based on users.role
        let mut students = Vec::new();
        for p in participants {
            if let Some(user) = users::Entity::find_by_id(p.user_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                if user.role == "student" {
                    students.push(p.user_id);
                }
            }
        }
        Ok(students)
    }
}
