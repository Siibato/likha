use sea_orm::{ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, Set};

use crate::seed::specs::UserSpec;
use crate::utils::AppError;
use ::entity::users;

const CHUNK_SIZE: usize = 100;

pub async fn insert_users(db: &DatabaseConnection, specs: &[UserSpec]) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let models: Vec<users::ActiveModel> = specs
        .iter()
        .map(|spec| users::ActiveModel {
            id: Set(spec.id),
            username: Set(spec.username.clone()),
            password_hash: Set(spec.password_hash.clone()),
            first_name: Set(spec.first_name.clone()),
            last_name: Set(spec.last_name.clone()),
            role: Set(spec.role.clone()),
            account_status: Set(spec.account_status.clone()),
            activated_at: Set(spec.activated_at),
            created_at: Set(spec.created_at),
            updated_at: Set(spec.created_at),
            deleted_at: Set(spec.deleted_at),
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        users::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

pub async fn delete_non_admin_users(db: &DatabaseConnection) -> Result<(), AppError> {
    users::Entity::delete_many()
        .filter(users::Column::Role.ne("admin"))
        .exec(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    Ok(())
}
