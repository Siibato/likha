use uuid::Uuid;
use crate::modules::grading::schema::{GradeItemResponse, GradeScoreResponse, CreateGradeItemRequest};
use crate::utils::AppResult;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn create_grade_item(
        &self,
        class_id: Uuid,
        request: CreateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        let term_number = request.term_number.unwrap_or(1);
        let existing = self
            .repo
            .get_items_by_component(class_id, term_number, &request.component)
            .await?;
        let order_index = existing.len() as i32;
        let source_type = request.source_type.unwrap_or_else(|| "manual".to_string());
        let source_id = request.source_id;
        let item = self
            .repo
            .create_item(
                class_id,
                request.title,
                request.component,
                Some(term_number),
                request.total_points,
                source_type,
                source_id,
                order_index,
            )
            .await?;

        let enrolled = self.repo.get_enrolled_student_ids(class_id).await?;
        for (student_id, _first, _last) in &enrolled {
            self.repo.upsert_score(item.id, *student_id, Some(0.0), true).await?;
        }
        tracing::info!(
            "Initialized {} score=0 rows for grade_item {} in class {}",
            enrolled.len(),
            item.id,
            class_id
        );

        let score_models = self.repo.get_scores_by_item(item.id).await?;
        let scores: Vec<GradeScoreResponse> =
            score_models.into_iter().map(GradeScoreResponse::from).collect();

        if let Some(ref inv) = self.invalidator {
            inv.invalidate_class_grades(class_id, term_number).await;
        }
        let mut response = GradeItemResponse::from(item);
        response.scores = scores;
        Ok(response)
    }
}
