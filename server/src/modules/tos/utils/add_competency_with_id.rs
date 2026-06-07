use uuid::Uuid;
use crate::modules::tos::schema::*;
use crate::utils::{AppError, AppResult};

impl crate::modules::tos::service::TosService {
    pub async fn add_competency_with_id(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
        competency_id: Uuid,
    ) -> AppResult<CompetencyResponse> {
        let tos = self.tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let existing = self.tos_repo.find_competencies_by_tos(tos_id).await?;
        let order_index = request.order_index.unwrap_or(existing.len() as i32);

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_tos_detail(tos_id).await;
            inv.invalidate_tos_list(tos.class_id).await;
        }

        let comp = self.tos_repo
            .create_competency(
                competency_id,
                tos_id,
                request.competency_code.as_deref(),
                &request.competency_text,
                request.time_units_taught,
                order_index,
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
            id: comp.id.to_string(),
            competency_code: comp.competency_code,
            competency_text: comp.competency_text,
            time_units_taught: comp.time_units_taught,
            order_index: comp.order_index,
            easy_count: comp.easy_count,
            medium_count: comp.medium_count,
            hard_count: comp.hard_count,
            remembering_count: comp.remembering_count,
            understanding_count: comp.understanding_count,
            applying_count: comp.applying_count,
            analyzing_count: comp.analyzing_count,
            evaluating_count: comp.evaluating_count,
            creating_count: comp.creating_count,
        })
    }
}
