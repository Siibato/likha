use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::class::schema::EnrollmentResponse;
use crate::schema::auth_schema::UserResponse;
use crate::modules::class::repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;

pub async fn add_student(
    class_repo: &ClassRepository,
    user_repo: &UserRepository,
    class_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
    role: &str,
) -> AppResult<EnrollmentResponse> {
    let _class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if role == "teacher" && !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only manage your own classes".to_string(),
        ));
    }

    let student = user_repo
        .find_by_id(student_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

    if student.role != "student" {
        return Err(AppError::BadRequest("User is not a student".to_string()));
    }

    if class_repo.is_student_enrolled(class_id, student_id).await? {
        return Err(AppError::BadRequest(
            "Student is already enrolled in this class".to_string(),
        ));
    }

    let enrollment = class_repo.add_student(class_id, student_id).await?;

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
