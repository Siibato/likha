use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::schema::auth_schema::UserResponse;
use crate::schema::class_schema::{
    ClassDetailResponse, ClassListResponse, ClassResponse, CreateClassRequest, EnrollmentResponse,
};
use crate::utils::error::{AppError, AppResult};

pub struct ClassService {
    class_repo: ClassRepository,
    user_repo: UserRepository,
}

impl ClassService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db),
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

        let class = self
            .class_repo
            .create_class(request.title.trim().to_string(), request.description, teacher_id)
            .await?;

        Ok(ClassResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: class.teacher_id,
            is_archived: class.is_archived,
            student_count: 0,
            created_at: class.created_at.to_string(),
            updated_at: class.updated_at.to_string(),
        })
    }

    pub async fn get_teacher_classes(&self, teacher_id: Uuid) -> AppResult<ClassListResponse> {
        let classes = self.class_repo.find_by_teacher_id(teacher_id).await?;

        let mut class_responses = Vec::new();
        for class in classes {
            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: class.teacher_id,
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

        self.class_repo.remove_student(class_id, student_id).await
    }

    pub async fn get_student_classes(&self, student_id: Uuid) -> AppResult<ClassListResponse> {
        let classes = self
            .class_repo
            .find_classes_by_student_id(student_id)
            .await?;

        let mut class_responses = Vec::new();
        for class in classes {
            let student_count = self.class_repo.count_students_in_class(class.id).await?;
            class_responses.push(ClassResponse {
                id: class.id,
                title: class.title,
                description: class.description,
                teacher_id: class.teacher_id,
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
}
