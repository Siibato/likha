use sea_orm::*;
use uuid::Uuid;

use ::entity::{class_participants, classes, users};
use crate::utils::{AppError, AppResult};

pub async fn find_by_user_id(
    db: &DatabaseConnection,
    user_id: Uuid,
    role: &str,
) -> AppResult<Vec<classes::Model>> {
    let user = users::Entity::find_by_id(user_id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    if user.is_none() || user.as_ref().unwrap().role != role {
        return Ok(vec![]);
    }

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
        .order_by_desc(classes::Column::CreatedAt)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
