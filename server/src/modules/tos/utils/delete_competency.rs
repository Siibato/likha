use crate::utils::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::tos::service::TosService {
    pub async fn delete_competency(&self, competency_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let comp = self
            .tos_repo
            .find_competency_by_id(competency_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

        let tos = self
            .tos_repo
            .find_tos_by_id(comp.tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self
            .class_repo
            .is_teacher_of_class(teacher_id, tos.class_id)
            .await?
        {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.tos_repo.soft_delete_competency(competency_id).await?;
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_tos_detail(tos.id).await;
            inv.invalidate_tos_list(tos.class_id).await;
        }
        Ok(())
    }
}
