use sea_orm::*;
use uuid::Uuid;

use ::entity::users;
use crate::utils::AppResult;
use super::{PaginatedRecords, helpers};

pub async fn get_users_paginated(
    db: &DatabaseConnection,
    user_ids: Vec<Uuid>,
    limit: i64,
) -> AppResult<PaginatedRecords> {
    let query = users::Entity::find()
        .filter(users::Column::Id.is_in(user_ids));
    helpers::paginate_query(db, query, limit, |r| {
        let is_active = r.account_status != "locked" && r.account_status != "deactivated";
        serde_json::json!({
            "id": r.id.to_string(),
            "username": r.username,
            "full_name": r.full_name,
            "role": r.role,
            "account_status": r.account_status,
            "is_active": is_active,
            "activated_at": r.activated_at.map(|d| d.to_string()),
            "created_at": r.created_at.to_string(),
            "updated_at": r.updated_at.to_string(),
        })
    })
    .await
}
