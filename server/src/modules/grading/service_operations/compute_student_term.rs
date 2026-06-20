use uuid::Uuid;
use crate::modules::grading::schema::TermGradeResponse;
use crate::utils::{AppError, AppResult};
use crate::modules::grading::helpers::deped_weights;
use crate::modules::grading::helpers::compute_component::compute_component;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_student_term(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        term_number: i32,
    ) -> AppResult<TermGradeResponse> {
        let config = self
            .repo
            .get_config(class_id, term_number)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(
                    "Grading config not set up for this class/period".to_string(),
                )
            })?;

        let items = self.repo.get_items(class_id, term_number).await?;

        let mut ww_items = Vec::new();
        let mut pt_items = Vec::new();
        let mut qa_items = Vec::new();
        for item in &items {
            match item.component.as_str() {
                "written_work" => ww_items.push(item),
                "performance_task" => pt_items.push(item),
                "period_assessment" => qa_items.push(item),
                _ => {}
            }
        }

        let scores = self
            .repo
            .get_scores_by_student_class_period(student_id, class_id, term_number)
            .await?;

        let mut score_map = std::collections::HashMap::new();
        for s in &scores {
            let effective = s.override_score.or(s.score);
            if let Some(eff) = effective {
                score_map.insert(s.grade_item_id, eff);
            }
        }

        let (_, ww_weighted) = compute_component(&ww_items, &score_map, config.ww_weight);
        let (_, pt_weighted) = compute_component(&pt_items, &score_map, config.pt_weight);
        let (_, qa_weighted) = compute_component(&qa_items, &score_map, config.qa_weight);

        let initial_grade = ww_weighted + pt_weighted + qa_weighted;
        let transmuted = deped_weights::transmute_grade(initial_grade);
        let is_locked = items.iter().all(|item| score_map.contains_key(&item.id));

        let model = self
            .repo
            .upsert_term_grade(
                class_id,
                student_id,
                term_number,
                initial_grade,
                transmuted,
                is_locked,
            )
            .await?;

        Ok(TermGradeResponse::from(model))
    }
}
