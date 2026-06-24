use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::modules::admin::repository_operations::activity_log as ops;
use crate::utils::AppResult;
use ::entity::activity_logs;

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
        ops::create_log(&self.db, user_id, action, details).await
    }

    pub async fn find_by_user_id(&self, user_id: Uuid) -> AppResult<Vec<activity_logs::Model>> {
        ops::find_by_user_id(&self.db, user_id).await
    }
}
