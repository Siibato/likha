use uuid::Uuid;
use crate::modules::tos::schema::*;
use crate::utils::AppResult;

impl crate::modules::tos::service::TosService {
    pub async fn add_competency(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
        self.add_competency_with_id(tos_id, teacher_id, request, Uuid::new_v4()).await
    }
}
