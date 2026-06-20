use uuid::Uuid;
use crate::modules::grading::schema::{GradeItemResponse, UpdateGradeItemRequest};
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn update_grade_item(
        &self,
        id: Uuid,
        request: UpdateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        let existing = self.repo.find_item(id).await?;
        let item = self
            .repo
            .update_item(id, request.title, request.component, request.total_points, request.order_index, request.source_type, request.source_id)
            .await?;
        if let Some(ref inv) = self.invalidator {
            if let Some(ref existing) = existing {
                let class_id = existing.class_id;
                let period = existing.term_number.unwrap_or(1);
                inv.invalidate_class_grades(class_id, period).await;
            }
        }
        Ok(GradeItemResponse::from(item))
    }
}
