use crate::modules::admin::ActivityLogRepository;
use crate::utils::AppResult;
use ::entity::activity_logs;
use uuid::Uuid;

pub async fn get_activity_logs(
    activity_log_repo: &ActivityLogRepository,
    user_id: Uuid,
) -> AppResult<Vec<activity_logs::Model>> {
    activity_log_repo.find_by_user_id(user_id).await
}
