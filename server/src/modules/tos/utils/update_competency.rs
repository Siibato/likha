use crate::modules::tos::schema::*;
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::tos::service::TosService {
    pub async fn update_competency(
        &self,
        competency_id: Uuid,
        teacher_id: Uuid,
        request: UpdateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
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

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_tos_detail(tos.id).await;
            inv.invalidate_tos_list(tos.class_id).await;
        }

        let updated = self
            .tos_repo
            .update_competency(
                competency_id,
                None,
                request.competency_text.as_deref(),
                request.time_units_taught,
                request.order_index,
                request.easy_count,
                request.medium_count,
                request.hard_count,
                request.remembering_count,
                request.understanding_count,
                request.applying_count,
                request.analyzing_count,
                request.evaluating_count,
                request.creating_count,
            )
            .await?;

        Ok(CompetencyResponse {
            id: updated.id.to_string(),
            competency_code: updated.competency_code,
            competency_text: updated.competency_text,
            time_units_taught: updated.time_units_taught,
            order_index: updated.order_index,
            easy_count: updated.easy_count,
            medium_count: updated.medium_count,
            hard_count: updated.hard_count,
            remembering_count: updated.remembering_count,
            understanding_count: updated.understanding_count,
            applying_count: updated.applying_count,
            analyzing_count: updated.analyzing_count,
            evaluating_count: updated.evaluating_count,
            creating_count: updated.creating_count,
        })
    }
}
