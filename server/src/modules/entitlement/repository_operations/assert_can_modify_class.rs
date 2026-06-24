use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::is_teacher_of_class::is_teacher_of_class;
use crate::utils::{AppError, AppResult};

pub async fn assert_can_modify_class(
    db: &DatabaseConnection,
    user_id: Uuid,
    user_role: &str,
    class_id: Uuid,
) -> AppResult<()> {
    if user_role == "admin" {
        return Ok(());
    }

    if user_role != "teacher" {
        return Err(AppError::Forbidden(
            "Only teachers and admins can modify classes".to_string(),
        ));
    }

    if !is_teacher_of_class(db, user_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only modify your own classes".to_string(),
        ));
    }

    Ok(())
}
