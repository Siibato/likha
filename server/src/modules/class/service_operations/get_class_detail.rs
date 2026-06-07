use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::class::schema::{ClassDetailResponse, EnrollmentResponse};
use crate::modules::auth::schema::UserResponse;
use crate::modules::class::repository::ClassRepository;
use crate::modules::auth::UserRepository;

pub async fn get_class_detail(
    class_repo: &ClassRepository,
    _user_repo: &UserRepository,
    class_id: Uuid,
) -> AppResult<ClassDetailResponse> {
    let class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    // Single query to get all student participants with their user data
    let participants_with_users = class_repo
        .find_participants_with_users_by_class_id(class_id, Some("student"))
        .await?;

    let students: Vec<EnrollmentResponse> = participants_with_users
        .into_iter()
        .map(|(enrollment, user)| {
            let is_active = user.account_status != "locked" && user.account_status != "deactivated";
            EnrollmentResponse {
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
            }
        })
        .collect();

    let teacher = class_repo.find_teacher_of_class(class_id).await?
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
