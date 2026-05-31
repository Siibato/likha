use uuid::Uuid;
use crate::schema::grading_schema::{GradeItemResponse, UpdateGradeItemRequest};
use crate::utils::AppResult;

impl crate::services::grade_computation::GradeComputationService {
    pub async fn update_grade_item(
        &self,
        id: Uuid,
        request: UpdateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        let item = self
            .repo
            .update_item(id, request.title, request.component, request.total_points, request.order_index, request.source_type, request.source_id)
            .await?;
        Ok(GradeItemResponse::from(item))
    }
}
