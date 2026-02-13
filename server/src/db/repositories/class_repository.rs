use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_enrollments, classes};
use crate::utils::{AppError, AppResult};

pub struct ClassRepository {
    db: DatabaseConnection,
}

impl ClassRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_class(
        &self,
        title: String,
        description: Option<String>,
        teacher_id: Uuid,
    ) -> AppResult<classes::Model> {
        let class = classes::ActiveModel {
            id: Set(Uuid::new_v4()),
            title: Set(title),
            description: Set(description),
            teacher_id: Set(teacher_id),
            is_archived: Set(false),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
        };

        class
            .insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create class: {}", e)))
    }

    pub async fn find_by_teacher_id(&self, teacher_id: Uuid) -> AppResult<Vec<classes::Model>> {
        classes::Entity::find()
            .filter(classes::Column::TeacherId.eq(teacher_id))
            .filter(classes::Column::IsArchived.eq(false))
            .order_by_desc(classes::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<classes::Model>> {
        classes::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_class(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<Option<String>>,
    ) -> AppResult<classes::Model> {
        let class = classes::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let mut active_class: classes::ActiveModel = class.into();
        active_class.updated_at = Set(Utc::now().naive_utc());

        if let Some(title) = title {
            active_class.title = Set(title);
        }

        if let Some(description) = description {
            active_class.description = Set(description);
        }

        active_class
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update class: {}", e)))
    }

    pub async fn add_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<class_enrollments::Model> {
        let enrollment = class_enrollments::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            student_id: Set(student_id),
            enrolled_at: Set(Utc::now().naive_utc()),
            removed_at: Set(None),
        };

        enrollment
            .insert(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to enroll student: {}", e))
            })
    }

    pub async fn remove_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<()> {
        let enrollment = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::ClassId.eq(class_id))
            .filter(class_enrollments::Column::StudentId.eq(student_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(enrollment) = enrollment {
            let update = class_enrollments::ActiveModel {
                id: Set(enrollment.id),
                removed_at: Set(Some(Utc::now().naive_utc())),
                ..Default::default()
            };

            update
                .update(&self.db)
                .await
                .map_err(|e| {
                    AppError::InternalServerError(format!("Failed to remove student: {}", e))
                })?;
        }

        Ok(())
    }

    pub async fn find_enrollments_by_class_id(
        &self,
        class_id: Uuid,
    ) -> AppResult<Vec<class_enrollments::Model>> {
        class_enrollments::Entity::find()
            .filter(class_enrollments::Column::ClassId.eq(class_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .order_by_asc(class_enrollments::Column::EnrolledAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_classes_by_student_id(
        &self,
        student_id: Uuid,
    ) -> AppResult<Vec<classes::Model>> {
        let enrollment_ids: Vec<Uuid> = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::StudentId.eq(student_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .into_iter()
            .map(|e| e.class_id)
            .collect();

        if enrollment_ids.is_empty() {
            return Ok(vec![]);
        }

        classes::Entity::find()
            .filter(classes::Column::Id.is_in(enrollment_ids))
            .filter(classes::Column::IsArchived.eq(false))
            .order_by_desc(classes::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn count_students_in_class(&self, class_id: Uuid) -> AppResult<usize> {
        let count = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::ClassId.eq(class_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .count(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(count as usize)
    }

    pub async fn is_student_enrolled(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<bool> {
        let enrollment = class_enrollments::Entity::find()
            .filter(class_enrollments::Column::ClassId.eq(class_id))
            .filter(class_enrollments::Column::StudentId.eq(student_id))
            .filter(class_enrollments::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(enrollment.is_some())
    }
}
