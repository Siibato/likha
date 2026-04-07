use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::class_schema::{ClassDetailResponse, EnrollmentResponse};
use crate::schema::auth_schema::UserResponse;

impl super::ClassService {
    pub async fn get_class_detail(&self, class_id: Uuid) -> AppResult<ClassDetailResponse> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let enrollments = self
            .class_repo
            .find_participants_by_class_id(class_id, Some("student"))
            .await?;

        let mut students = Vec::new();
        for enrollment in enrollments {
            if let Some(user) = self.user_repo.find_by_id(enrollment.user_id).await? {
                let is_active = user.account_status != "locked" && user.account_status != "deactivated";
                students.push(EnrollmentResponse {
                    id: enrollment.id,
                    student: UserResponse {
                        id: user.id,
                        username: user.username,
                        full_name: user.full_name,
                        role: user.role,
                        account_status: user.account_status,
                        is_active,
                        activated_at: user.activated_at.map(|dt| dt.to_string()),
                        created_at: user.created_at.to_string(),
                    },
                    joined_at: enrollment.joined_at.to_string(),
                });
            }
        }

        let teacher = self.class_repo.find_teacher_of_class(class_id).await?
            .ok_or_else(|| AppError::InternalServerError("Class has no teacher assigned".to_string()))?;

        Ok(ClassDetailResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: teacher.id,
            is_archived: class.is_archived,
            is_advisory: class.is_advisory,
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
        role: &str,
    ) -> AppResult<EnrollmentResponse> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        // Only enforce ownership check for teachers, not admins
        if role == "teacher" && !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only manage your own classes".to_string(),
            ));
        }

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

        let is_active = student.account_status != "locked" && student.account_status != "deactivated";

        Ok(EnrollmentResponse {
            id: enrollment.id,
            student: UserResponse {
                id: student.id,
                username: student.username,
                full_name: student.full_name,
                role: student.role,
                account_status: student.account_status,
                is_active,
                activated_at: student.activated_at.map(|dt| dt.to_string()),
                created_at: student.created_at.to_string(),
            },
            joined_at: enrollment.joined_at.to_string(),
        })
    }

    pub async fn remove_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
        role: &str,
    ) -> AppResult<()> {
        let _class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        // Only enforce ownership check for teachers, not admins
        if role == "teacher" && !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only manage your own classes".to_string(),
            ));
        }

        self.class_repo.remove_student(class_id, student_id).await?;

        Ok(())
    }

    pub async fn is_student_enrolled(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<bool> {
        self.class_repo.is_student_enrolled(class_id, student_id).await
    }
}