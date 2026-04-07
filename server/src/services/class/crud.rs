use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::validators::Validator;
use crate::schema::class_schema::{
    ClassResponse, ClassListResponse, CreateClassRequest, UpdateClassRequest,
};

impl super::ClassService {
    pub async fn create_class(
        &self,
        request: CreateClassRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<ClassResponse> {
        let title = Validator::validate_title(&request.title)?;

        // Use admin-provided teacher_id if present, otherwise use the requesting user's id
        let actual_teacher_id = request.teacher_id.unwrap_or(teacher_id);

        let teacher = self
            .user_repo
            .find_by_id(actual_teacher_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let existing_classes = self.class_repo.find_by_teacher_id(actual_teacher_id).await?;
        let normalized_title = title.to_lowercase();

        if existing_classes
            .iter()
            .any(|c| c.title.to_lowercase() == normalized_title)
        {
            return Err(AppError::BadRequest(
                format!("A class named '{}' already exists for this teacher", title)
            ));
        }

        let class = self
            .class_repo
            .create_class(title, request.description, actual_teacher_id, client_id, request.is_advisory.unwrap_or(false))
            .await?;


        Ok(ClassResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: actual_teacher_id,
            teacher_username: teacher.username,
            teacher_full_name: teacher.full_name,
            is_archived: class.is_archived,
            is_advisory: class.is_advisory,
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
        caller_role: &str,
    ) -> AppResult<ClassResponse> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        // Allow admin to update any class, otherwise check ownership
        if caller_role != "admin" && !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only update your own classes".to_string(),
            ));
        }

        let title = Validator::validate_optional_title(request.title)?;

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
                title,
                description,
                request.is_advisory,
            )
            .await?;

        // Handle teacher reassignment if requested
        if let Some(new_teacher_id) = request.teacher_id {
            let new_teacher = self
                .user_repo
                .find_by_id(new_teacher_id)
                .await?
                .ok_or_else(|| AppError::NotFound("New teacher not found".to_string()))?;

            if new_teacher.role != "teacher" {
                return Err(AppError::BadRequest("User must have teacher role".to_string()));
            }

            // Check that new teacher is not already assigned
            if self.class_repo.is_teacher_of_class(new_teacher_id, class_id).await? {
                return Err(AppError::BadRequest("Teacher is already assigned to this class".to_string()));
            }

            self.class_repo.reassign_teacher(class_id, new_teacher_id).await?;
        }

        let teacher_model = self
            .class_repo
            .find_teacher_of_class(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let student_count = self.class_repo.count_students_in_class(class_id).await?;


        Ok(ClassResponse {
            id: updated_class.id,
            title: updated_class.title,
            description: updated_class.description,
            teacher_id: teacher_model.id,
            teacher_username: teacher_model.username,
            teacher_full_name: teacher_model.full_name,
            is_archived: updated_class.is_archived,
            is_advisory: updated_class.is_advisory,
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
                teacher_id: teacher_id,
                teacher_username: teacher.username.clone(),
                teacher_full_name: teacher.full_name.clone(),
                is_archived: class.is_archived,
                is_advisory: class.is_advisory,
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
                .class_repo
                .find_teacher_of_class(class.id)
                .await?
                .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: teacher.id,
                teacher_username: teacher.username,
                teacher_full_name: teacher.full_name,
                is_archived: class.is_archived,
                is_advisory: class.is_advisory,
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
                .class_repo
                .find_teacher_of_class(class.id)
                .await?
                .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: teacher.id,
                teacher_username: teacher.username,
                teacher_full_name: teacher.full_name,
                is_archived: class.is_archived,
                is_advisory: class.is_advisory,
                student_count,
                created_at: class.created_at.to_string(),
                updated_at: class.updated_at.to_string(),
            });
        }

        Ok(ClassListResponse {
            classes: class_responses,
        })
    }

    pub async fn soft_delete(&self, class_id: Uuid, user_id: Uuid, role: &str) -> AppResult<()> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if role != "admin" && !self.class_repo.is_teacher_of_class(user_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only delete your own classes".to_string(),
            ));
        }

        // Soft-delete all participants (students and teachers) first
        self.class_repo.remove_all_participants(class_id).await?;
        self.class_repo.soft_delete(class_id).await?;

        Ok(())
    }
}