use sea_orm::DatabaseConnection;
use uuid::Uuid;
use md5;

use crate::db::repositories::change_log_repository::ChangeLogRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::schema::auth_schema::UserResponse;
use crate::schema::class_schema::{
    ClassDetailResponse, ClassListResponse, ClassResponse, CreateClassRequest, EnrollmentResponse, UpdateClassRequest, ClassMetadataResponse,
};
use crate::utils::error::{AppError, AppResult};

pub struct ClassService {
    class_repo: ClassRepository,
    user_repo: UserRepository,
    change_log_repo: ChangeLogRepository,
}

impl ClassService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db.clone()),
            change_log_repo: ChangeLogRepository::new(db),
        }
    }

    pub async fn create_class(
        &self,
        request: CreateClassRequest,
        teacher_id: Uuid,
    ) -> AppResult<ClassResponse> {
        if request.title.trim().is_empty() {
            return Err(AppError::BadRequest("Class title is required".to_string()));
        }

        let teacher = self
            .user_repo
            .find_by_id(teacher_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        // Deduplication check: prevent creating duplicate classes with same title
        let existing_classes = self.class_repo.find_by_teacher_id(teacher_id).await?;
        let normalized_title = request.title.trim().to_lowercase();

        if let Some(existing) = existing_classes
            .iter()
            .find(|c| c.title.to_lowercase() == normalized_title)
        {
            // Return existing class instead of creating duplicate
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
            .create_class(request.title.trim().to_string(), request.description, teacher_id)
            .await?;

        // Log change for sync
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
        // Verify class exists and belongs to the teacher
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

        // Validate title if provided
        if let Some(ref title) = request.title {
            if title.trim().is_empty() {
                return Err(AppError::BadRequest("Class title cannot be empty".to_string()));
            }
        }

        // Handle description: if provided, convert to Option<Option<String>>
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

        // Log change for sync
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

    pub async fn get_class_detail(&self, class_id: Uuid) -> AppResult<ClassDetailResponse> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let enrollments = self
            .class_repo
            .find_enrollments_by_class_id(class_id)
            .await?;

        let mut students = Vec::new();
        for enrollment in enrollments {
            if let Some(student) = self.user_repo.find_by_id(enrollment.student_id).await? {
                students.push(EnrollmentResponse {
                    id: enrollment.id,
                    student: UserResponse {
                        id: student.id,
                        username: student.username,
                        full_name: student.full_name,
                        role: student.role,
                        account_status: student.account_status,
                        is_active: student.is_active,
                        activated_at: student.activated_at.map(|dt| dt.to_string()),
                        created_at: student.created_at.to_string(),
                    },
                    enrolled_at: enrollment.enrolled_at.to_string(),
                });
            }
        }

        Ok(ClassDetailResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: class.teacher_id,
            is_archived: class.is_archived,
            students,
            created_at: class.created_at.to_string(),
            updated_at: class.updated_at.to_string(),
        })
    }

    pub async fn add_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<EnrollmentResponse> {
        // Verify class exists and belongs to the teacher
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only manage your own classes".to_string(),
            ));
        }

        // Verify student exists and is a student
        let student = self
            .user_repo
            .find_by_id(student_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        if student.role != "student" {
            return Err(AppError::BadRequest(
                "User is not a student".to_string(),
            ));
        }

        // Check if already enrolled
        if self
            .class_repo
            .is_student_enrolled(class_id, student_id)
            .await?
        {
            return Err(AppError::BadRequest(
                "Student is already enrolled in this class".to_string(),
            ));
        }

        let enrollment = self
            .class_repo
            .add_student(class_id, student_id)
            .await?;

        // Log change for sync
        let _ = self.change_log_repo.log_change(
            "enrollment",
            enrollment.id,
            "create",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "id": enrollment.id,
                "class_id": class_id,
                "student_id": student_id,
                "enrolled_at": enrollment.enrolled_at.to_string(),
            })).unwrap_or_default()),
        ).await;

        Ok(EnrollmentResponse {
            id: enrollment.id,
            student: UserResponse {
                id: student.id,
                username: student.username,
                full_name: student.full_name,
                role: student.role,
                account_status: student.account_status,
                is_active: student.is_active,
                activated_at: student.activated_at.map(|dt| dt.to_string()),
                created_at: student.created_at.to_string(),
            },
            enrolled_at: enrollment.enrolled_at.to_string(),
        })
    }

    pub async fn remove_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only manage your own classes".to_string(),
            ));
        }

        self.class_repo.remove_student(class_id, student_id).await?;

        // Log change for sync (generate a new UUID for the deletion record)
        // This tracks which student was removed from which class
        let enrollment_id = Uuid::new_v4();
        let _ = self.change_log_repo.log_change(
            "enrollment",
            enrollment_id,
            "delete",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "class_id": class_id,
                "student_id": student_id,
            })).unwrap_or_default()),
        ).await;

        Ok(())
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

    pub async fn get_classes_metadata(
        &self,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<ClassMetadataResponse> {
        let (last_modified, count, etag) = match role {
            "teacher" => self.class_repo.get_metadata(user_id).await?,
            "student" => {
                let enrollments = self.class_repo.find_student_enrollments(user_id).await?;
                let count = enrollments.len();
                let etag = format!("{:x}", md5::compute(format!("student-{}-{}", user_id, count).as_bytes()));
                (chrono::Utc::now().naive_utc(), count, etag)
            }
            _ => return Err(AppError::Forbidden("Invalid role".to_string())),
        };

        Ok(ClassMetadataResponse {
            last_modified: last_modified.to_string(),
            record_count: count,
            etag,
        })
    }

    /// Soft delete a class (marks it deleted for sync, doesn't remove from DB)
    pub async fn soft_delete(&self, class_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        // Verify class exists and belongs to teacher
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

        // Mark as deleted at current time
        self.class_repo.soft_delete(class_id).await?;

        // Log the deletion
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
