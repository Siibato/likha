use async_trait::async_trait;
use uuid::Uuid;
use super::sync_push_service::{OperationResult, SyncQueueEntry};

#[async_trait]
pub trait PushDelegate: Send + Sync {
    fn can_handle(&self, entity_type: &str) -> bool;

    async fn process(
        &self,
        user_id: Uuid,
        user_role: &str,
        op: &SyncQueueEntry,
    ) -> OperationResult;
}
