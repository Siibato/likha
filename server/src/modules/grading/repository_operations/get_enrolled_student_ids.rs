use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, users};
use crate::utils::{AppError, AppResult};

pub async fn get_enrolled_student_ids(
    db: &DatabaseConnection,
    class_id: Uuid,
) -> AppResult<Vec<(Uuid, String)>> {
    use sea_orm::QuerySelect;

    let participants = class_participants::Entity::find()
        .select_only()
        .column_as(class_participants::Column::UserId, "user_id")
        .column_as(users::Column::FullName, "full_name")
        .join(
            sea_orm::JoinType::InnerJoin,
            class_participants::Relation::User.def(),
        )
        .filter(class_participants::Column::ClassId.eq(class_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .filter(users::Column::Role.eq("student"))
        .into_tuple::<(Uuid, String)>()
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    Ok(participants)
}
