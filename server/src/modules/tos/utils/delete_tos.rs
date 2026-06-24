use crate::utils::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::tos::service::TosService {
    pub async fn delete_tos(&self, tos_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let tos = self
            .tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self
            .class_repo
            .is_teacher_of_class(teacher_id, tos.class_id)
            .await?
        {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.tos_repo.soft_delete_tos(tos_id).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_tos_detail(tos_id).await;
            inv.invalidate_tos_list(tos.class_id).await;
        }
        Ok(())
    }
}
