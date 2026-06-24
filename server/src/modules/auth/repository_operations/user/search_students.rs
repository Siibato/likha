use sea_orm::*;

use crate::utils::{AppError, AppResult};
use ::entity::users;

pub async fn search_students(db: &DatabaseConnection, query: &str) -> AppResult<Vec<users::Model>> {
    let mut condition = Condition::all().add(users::Column::Role.eq("student"));

    if !query.is_empty() {
        condition = condition.add(
            Condition::any()
                .add(users::Column::Username.contains(query))
                .add(users::Column::FirstName.contains(query))
                .add(users::Column::LastName.contains(query)),
        );
    }

    users::Entity::find()
        .filter(condition)
        .order_by_asc(users::Column::LastName)
        .order_by_asc(users::Column::FirstName)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
}
