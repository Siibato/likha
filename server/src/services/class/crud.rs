use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::class_schema::{
    ClassResponse, ClassListResponse, CreateClassRequest, UpdateClassRequest,
};

impl super::ClassService {
    pub async fn create_class(
        &self,
        request: CreateClassRequest,
        teacher_id: Uuid,
    ) -> AppResult<ClassResponse> {
        if request.title.trim().is_empty() {
            return Err(AppError::BadRequest("Class title is required".to_string()));
        }

        // Use admin-provided teacher_id if present, otherwise use the requesting user's id
        let actual_teacher_id = request.teacher_id.unwrap_or(teacher_id);

        let teacher = self
            .user_repo
            .find_by_id(actual_teacher_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let existing_classes = self.class_repo.find_by_teacher_id(actual_teacher_id).await?;
        let normalized_title = request.title.trim().to_lowercase();

        if let Some(existing) = existing_classes
            .iter()
            .find(|c| c.title.to_lowercase() == normalized_title)
        {
            return Ok(ClassResponse {
                id: existing.id,
                title: existing.title.clone(),
                description: existing.description.clone(),
                teacher_id: existing.teacher_id,
                teacher_username: teacher.username.clone(),
                teacher_full_name: teacher.full_name.clone(),
                is_archived: existing.is_archived,
                student_count: 0,
                created_at: existing.created_at.to_string(),
                updated_at: existing.updated_at.to_string(),
            });
        }

        let class = self
            .class_repo
            .create_class(request.title.trim().to_string(), request.description, actual_teacher_id)
            .await?;

        let _ = self.change_log_repo.log_change(
            "class",
            class.id,
            "create",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "id": class.id,
                "title": class.title,
                "description": class.description,
                "teacher_id": class.teacher_id,
                "is_archived": class.is_archived,
                "created_at": class.created_at.to_string(),
                "updated_at": class.updated_at.to_string(),
            })).unwrap_or_default()),
        ).await;

        Ok(ClassResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: class.teacher_id,
            teacher_username: teacher.username,
            teacher_full_name: teacher.full_name,
            is_archived: class.is_archived,
            student_count: 0,
            created_at: class.created_at.to_string(),
            updated_at: class.updated_at.to_string(),
        })
    }

    pub async fn update_class(
        &self,
        class_id: Uuid,
        request: UpdateClassRequest,
        teacher_id: Uuid,
    ) -> AppResult<ClassResponse> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only update your own classes".to_string(),
            ));
        }

        if let Some(ref title) = request.title {
            if title.trim().is_empty() {
                return Err(AppError::BadRequest("Class title cannot be empty".to_string()));
            }
        }

        let description = request.description.map(|d| {
            let trimmed = d.trim();
            if trimmed.is_empty() {
                None
            } else {
                Some(trimmed.to_string())
            }
        });

        let updated_class = self
            .class_repo
            .update_class(
                class_id,
                request.title.map(|t| t.trim().to_string()),
                description,
            )
            .await?;

        let teacher = self
            .user_repo
            .find_by_id(updated_class.teacher_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let student_count = self.class_repo.count_students_in_class(class_id).await?;

        let _ = self.change_log_repo.log_change(
            "class",
            updated_class.id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "id": updated_class.id,
                "title": updated_class.title,
                "description": updated_class.description,
                "teacher_id": updated_class.teacher_id,
                "is_archived": updated_class.is_archived,
                "created_at": updated_class.created_at.to_string(),
                "updated_at": updated_class.updated_at.to_string(),
            })).unwrap_or_default()),
        ).await;

        Ok(ClassResponse {
            id: updated_class.id,
            title: updated_class.title,
            description: updated_class.description,
            teacher_id: updated_class.teacher_id,
            teacher_username: teacher.username,
            teacher_full_name: teacher.full_name,
            is_archived: updated_class.is_archived,
            student_count,
            created_at: updated_class.created_at.to_string(),
            updated_at: updated_class.updated_at.to_string(),
        })
    }

    pub async fn get_teacher_classes(&self, teacher_id: Uuid) -> AppResult<ClassListResponse> {
        let teacher = self
            .user_repo
            .find_by_id(teacher_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let classes = self.class_repo.find_by_teacher_id(teacher_id).await?;

        let mut class_responses = Vec::new();
        for class in classes {
            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: class.teacher_id,
                teacher_username: teacher.username.clone(),
                teacher_full_name: teacher.full_name.clone(),
                is_archived: class.is_archived,
                student_count,
                created_at: class.created_at.to_string(),
                updated_at: class.updated_at.to_string(),
            });
        }

        Ok(ClassListResponse {
            classes: class_responses,
        })
    }

    pub async fn get_student_classes(&self, student_id: Uuid) -> AppResult<ClassListResponse> {
        let classes = self
            .class_repo
            .find_classes_by_student_id(student_id)
            .await?;

        let mut class_responses = Vec::new();
        for class in classes {
            let teacher = self
                .user_repo
                .find_by_id(class.teacher_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: class.teacher_id,
                teacher_username: teacher.username,
                teacher_full_name: teacher.full_name,
                is_archived: class.is_archived,
                student_count,
                created_at: class.created_at.to_string(),
                updated_at: class.updated_at.to_string(),
            });
        }

        Ok(ClassListResponse {
            classes: class_responses,
        })
    }

    pub async fn get_all_classes(&self) -> AppResult<ClassListResponse> {
        let classes = self.class_repo.find_all().await?;

        let mut class_responses = Vec::new();
        for class in classes {
            let teacher = self
                .user_repo
                .find_by_id(class.teacher_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: class.teacher_id,
                teacher_username: teacher.username,
                teacher_full_name: teacher.full_name,
                is_archived: class.is_archived,
                student_count,
                created_at: class.created_at.to_string(),
                updated_at: class.updated_at.to_string(),
            });
        }

        Ok(ClassListResponse {
            classes: class_responses,
        })
    }

    pub async fn soft_delete(&self, class_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only delete your own classes".to_string(),
            ));
        }

        self.class_repo.soft_delete(class_id).await?;

        let _ = self.change_log_repo.log_change(
            "class",
            class_id,
            "delete",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "id": class_id,
                "title": class.title,
            })).unwrap_or_default()),
        ).await;

        Ok(())
    }
}