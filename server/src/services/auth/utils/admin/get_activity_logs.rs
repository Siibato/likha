use uuid::Uuid;
use crate::utils::AppResult;
use ::entity::activity_logs;

impl crate::services::auth::AuthService {
    pub async fn get_activity_logs(&self, user_id: Uuid) -> AppResult<Vec<activity_logs::Model>> {
        self.activity_log_repo.find_by_user_id(user_id).await
    }
}
