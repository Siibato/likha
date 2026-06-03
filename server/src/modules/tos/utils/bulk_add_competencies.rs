use uuid::Uuid;
use crate::modules::tos::schema::*;
use crate::utils::{AppError, AppResult};

impl crate::modules::tos::service::TosService {
    pub async fn bulk_add_competencies(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: BulkAddCompetenciesRequest,
    ) -> AppResult<Vec<CompetencyResponse>> {
        let tos = self.tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let existing = self.tos_repo.find_competencies_by_tos(tos_id).await?;
        let base_order = existing.len() as i32;

        let competencies: Vec<_> = request
            .competencies
            .into_iter()
            .enumerate()
            .map(|(i, c)| {
                (
                    c.competency_code,
                    c.competency_text,
                    c.time_units_taught,
                    c.order_index.unwrap_or(base_order + i as i32),
                    c.easy_count,
                    c.medium_count,
                    c.hard_count,
                    c.remembering_count,
                    c.understanding_count,
                    c.applying_count,
                    c.analyzing_count,
                    c.evaluating_count,
                    c.creating_count,
                )
            })
            .collect();

        let created = self.tos_repo.bulk_create_competencies(tos_id, competencies).await?;

        Ok(created
            .into_iter()
            .map(|c| CompetencyResponse {
                id: c.id.to_string(),
                competency_code: c.competency_code,
                competency_text: c.competency_text,
                time_units_taught: c.time_units_taught,
                order_index: c.order_index,
                easy_count: c.easy_count,
                medium_count: c.medium_count,
                hard_count: c.hard_count,
                remembering_count: c.remembering_count,
                understanding_count: c.understanding_count,
                applying_count: c.applying_count,
                analyzing_count: c.analyzing_count,
                evaluating_count: c.evaluating_count,
                creating_count: c.creating_count,
            })
            .collect())
    }
}
