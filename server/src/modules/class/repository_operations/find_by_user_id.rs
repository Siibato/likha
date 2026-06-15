use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, classes};
use crate::utils::{AppError, AppResult};

pub async fn find_by_user_id(
    db: &DatabaseConnection,
    user_id: Uuid,
    _role: &str,
) -> AppResult<Vec<classes::Model>> {
    let class_ids: Vec<Uuid> = class_participants::Entity::find()
        .filter(class_participants::Column::UserId.eq(user_id))
        .filter(class_participants::Column::RemovedAt.is_null())
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
        .into_iter()
        .map(|p| p.class_id)
        .collect();

    if class_ids.is_empty() {
        return Ok(vec![]);
    }

    classes::Entity::find()
        .filter(classes::Column::Id.is_in(class_ids))
        .filter(classes::Column::IsArchived.eq(false))
        .filter(classes::Column::DeletedAt.is_null())
        .order_by_desc(classes::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
