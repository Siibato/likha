use sea_orm::{ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, Set};

use crate::modules::auth::UserRepository;
use crate::seed::specs::UserSpec;
use crate::utils::AppError;
use ::entity::users;

pub async fn insert_users(db: &DatabaseConnection, specs: &[UserSpec]) -> Result<(), AppError> {
    let repo = UserRepository::new(db.clone());

    for spec in specs {
        repo.create_account(
            spec.username.clone(),
            spec.first_name.clone(),
            spec.last_name.clone(),
            spec.role.clone(),
            Some(spec.id),
        )
        .await?;

        if let Some(hash) = &spec.password_hash {
            repo.set_password(spec.id, hash.clone()).await?;
        }

        let user = users::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("User {} not found", spec.id)))?;

        let mut am: users::ActiveModel = user.into();
        am.created_at = Set(spec.created_at);
        am.updated_at = Set(spec.created_at);
        am.account_status = Set(spec.account_status.clone());
        am.activated_at = Set(spec.activated_at);
        am.deleted_at = Set(spec.deleted_at);
        am.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
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
