use uuid::Uuid;
use crate::schema::tos_schema::*;
use crate::utils::AppResult;

impl crate::services::tos::TosService {
    pub async fn add_competency(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
        self.add_competency_with_id(tos_id, teacher_id, request, Uuid::new_v4()).await
    }
}
