use sea_orm::{ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter};
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::auth::UserRepository;
use crate::modules::auth::helpers::user_to_response;
use crate::modules::admin::schema::{AccountDetailResponse, TeacherDetailsResponse};
use crate::modules::student_records::schema::LearnerDetailsResponse;
use crate::modules::student_records::repository_operations::get_learner_details::get_learner_details;

pub async fn get_account_details(
    db: &DatabaseConnection,
    user_repo: &UserRepository,
    user_id: Uuid,
) -> AppResult<AccountDetailResponse> {
    let user = user_repo.find_by_id(user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    let user_response = user_to_response(&user);

    let (learner_details, teacher_details) = match user.role.as_str() {
        "student" => {
            let ld = get_learner_details(db, user_id).await?
                .map(LearnerDetailsResponse::from);
            (ld, None)
        }
        "teacher" => {
            let td = get_teacher_details(db, user_id).await?
                .map(TeacherDetailsResponse::from);
            (None, td)
        }
        _ => (None, None),
    };

    Ok(AccountDetailResponse {
        user: user_response,
        learner_details,
        teacher_details,
    })
}

pub async fn get_teacher_details(
    db: &DatabaseConnection,
    user_id: Uuid,
) -> AppResult<Option<::entity::teacher_details::Model>> {
    use ::entity::teacher_details;
    teacher_details::Entity::find()
        .filter(teacher_details::Column::UserId.eq(user_id))
        .filter(teacher_details::Column::DeletedAt.is_null())
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
