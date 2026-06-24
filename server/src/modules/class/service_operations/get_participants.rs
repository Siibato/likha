use crate::modules::auth::schema::UserResponse;
use crate::modules::class::repository::ClassRepository;
use crate::modules::class::schema::EnrollmentResponse;
use crate::utils::error::{AppError, AppResult};
use uuid::Uuid;

pub async fn get_participants(
    class_repo: &ClassRepository,
    class_id: Uuid,
) -> AppResult<Vec<EnrollmentResponse>> {
    let _class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

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
                    first_name: user.first_name,
                    last_name: user.last_name,
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

    Ok(students)
}
