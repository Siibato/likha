use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::activity_logs;
use crate::utils::{AppError, AppResult};

pub struct ActivityLogRepository {
    db: DatabaseConnection,
}

impl ActivityLogRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_log(
        &self,
        user_id: Uuid,
        action: &str,
        details: Option<String>,
    ) -> AppResult<activity_logs::Model> {
        let log = activity_logs::ActiveModel {
            id: Set(Uuid::new_v4()),
            user_id: Set(user_id),
            action: Set(action.to_string()),
            details: Set(details),
            created_at: Set(Utc::now().naive_utc()),
        };

        log.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create activity log: {}", e)))
    }

    pub async fn find_by_user_id(&self, user_id: Uuid) -> AppResult<Vec<activity_logs::Model>> {
        activity_logs::Entity::find()
            .filter(activity_logs::Column::UserId.eq(user_id))
            .order_by_desc(activity_logs::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }
}
