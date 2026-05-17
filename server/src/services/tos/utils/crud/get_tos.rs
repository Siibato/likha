use uuid::Uuid;
use crate::schema::tos_schema::*;
use crate::utils::{AppError, AppResult};

impl crate::services::tos::TosService {
    pub async fn get_tos(&self, tos_id: Uuid) -> AppResult<TosResponse> {
        let tos = self.tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        let competencies = self.tos_repo.find_competencies_by_tos(tos_id).await?;

        Ok(TosResponse {
            id: tos.id.to_string(),
            class_id: tos.class_id.to_string(),
            grading_period_number: tos.grading_period_number,
            title: tos.title,
            classification_mode: tos.classification_mode,
            total_items: tos.total_items,
            time_unit: tos.time_unit,
            easy_percentage: tos.easy_percentage,
            medium_percentage: tos.medium_percentage,
            hard_percentage: tos.hard_percentage,
            remembering_percentage: tos.remembering_percentage,
            understanding_percentage: tos.understanding_percentage,
            applying_percentage: tos.applying_percentage,
            analyzing_percentage: tos.analyzing_percentage,
            evaluating_percentage: tos.evaluating_percentage,
            creating_percentage: tos.creating_percentage,
            competencies: competencies
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
                .collect(),
            created_at: tos.created_at.to_string(),
            updated_at: tos.updated_at.to_string(),
        })
    }
}
