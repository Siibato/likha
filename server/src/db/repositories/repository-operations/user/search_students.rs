use sea_orm::*;

use ::entity::users;
use crate::utils::{AppError, AppResult};

pub async fn search_students(db: &DatabaseConnection, query: &str) -> AppResult<Vec<users::Model>> {
    let mut condition = Condition::all().add(users::Column::Role.eq("student"));

    if !query.is_empty() {
        condition = condition.add(
            Condition::any()
                .add(users::Column::Username.contains(query))
                .add(users::Column::FullName.contains(query)),
        );
    }

    users::Entity::find()
        .filter(condition)
        .order_by_asc(users::Column::FullName)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
