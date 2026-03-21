use sea_orm::EntityTrait;
use uuid::Uuid;

use crate::schema::grading_schema::*;
use crate::utils::{AppError, AppResult};

use super::deped_weights;

impl super::GradeComputationService {
    /// Compute quarterly grade for a single student.
    pub async fn compute_student_quarterly(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        quarter: i32,
    ) -> AppResult<QuarterlyGradeResponse> {
        // 1. Get weight config for this class/quarter
        let config = self
            .repo
            .get_config(class_id, quarter)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(
                    "Grading config not set up for this class/quarter".to_string(),
                )
            })?;

        // 2. Get all grade items for this class/quarter
        let items = self.repo.get_items(class_id, quarter).await?;

        // 3. Group items by component
        let mut ww_items = Vec::new();
        let mut pt_items = Vec::new();
        let mut qa_items = Vec::new();
        for item in &items {
            match item.component.as_str() {
                "written_work" => ww_items.push(item),
                "performance_task" => pt_items.push(item),
                "quarterly_assessment" => qa_items.push(item),
                _ => {}
            }
        }

        // 4. Get all scores for this student in this class/quarter
        let scores = self
            .repo
            .get_scores_by_student_class_quarter(student_id, class_id, quarter)
            .await?;

        // Build a map of grade_item_id -> effective_score
        let mut score_map = std::collections::HashMap::new();
        for s in &scores {
            let effective = s.override_score.or(s.score);
            if let Some(eff) = effective {
                score_map.insert(s.grade_item_id, eff);
            }
        }

        // 5. Compute per-component
        let (ww_pct, ww_weighted) =
            compute_component(&ww_items, &score_map, config.ww_weight);
        let (pt_pct, pt_weighted) =
            compute_component(&pt_items, &score_map, config.pt_weight);
        let (qa_pct, qa_weighted) =
            compute_component(&qa_items, &score_map, config.qa_weight);

        // 6. Initial grade
        let initial_grade = ww_weighted + pt_weighted + qa_weighted;

        // 7. Transmute
        let transmuted = deped_weights::transmute_grade(initial_grade);

        // 8. Determine completeness: all items have scores
        let is_complete = items.iter().all(|item| score_map.contains_key(&item.id));

        // 9. Upsert quarterly grade
        let model = self
            .repo
            .upsert_quarterly_grade(
                class_id,
                student_id,
                quarter,
                ww_pct,
                pt_pct,
                qa_pct,
                ww_weighted,
                pt_weighted,
                qa_weighted,
                initial_grade,
                transmuted,
                is_complete,
            )
            .await?;

        Ok(QuarterlyGradeResponse::from(model))
    }

    /// Compute quarterly grades for all enrolled students in a class.
    pub async fn compute_class_quarterly(
        &self,
        class_id: Uuid,
        quarter: i32,
    ) -> AppResult<Vec<QuarterlyGradeResponse>> {
        let student_ids = self.repo.get_enrolled_student_ids(class_id).await?;
        let mut results = Vec::new();
        for student_id in student_ids {
            let result = self
                .compute_student_quarterly(class_id, student_id, quarter)
                .await?;
            results.push(result);
        }
        Ok(results)
    }

    /// Compute final grade for a student (average of quarterly transmuted grades).
    pub async fn compute_final_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<FinalGradeResponse> {
        let quarters = self
            .repo
            .get_all_for_student(class_id, student_id)
            .await?;

        let quarterly_responses: Vec<QuarterlyGradeResponse> =
            quarters.into_iter().map(QuarterlyGradeResponse::from).collect();

        // Compute average of complete quarterly transmuted grades
        let complete_grades: Vec<f64> = quarterly_responses
            .iter()
            .filter(|q| q.is_complete)
            .filter_map(|q| q.transmuted_grade.map(|t| t as f64))
            .collect();

        let final_grade = if complete_grades.is_empty() {
            None
        } else {
            Some(complete_grades.iter().sum::<f64>() / complete_grades.len() as f64)
        };

        Ok(FinalGradeResponse {
            student_id: student_id.to_string(),
            quarterly_grades: quarterly_responses,
            final_grade,
        })
    }

    /// Get grade summary for all students in a class/quarter.
    pub async fn get_grade_summary(
        &self,
        class_id: Uuid,
        quarter: i32,
    ) -> AppResult<GradeSummaryResponse> {
        let config = self
            .repo
            .get_config(class_id, quarter)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(
                    "Grading config not set up for this class/quarter".to_string(),
                )
            })?;

        let quarterly_grades = self.repo.get_all_for_class(class_id, quarter).await?;

        // Get student names via participants + users
        let participants = self
            .class_repo
            .find_participants_by_class_id(class_id, None)
            .await?;

        let mut student_name_map: std::collections::HashMap<Uuid, String> =
            std::collections::HashMap::new();
        for p in &participants {
            if let Ok(Some(user)) = ::entity::users::Entity::find_by_id(p.user_id)
                .one(&self.db)
                .await
            {
                student_name_map.insert(p.user_id, user.full_name);
            }
        }

        let students = quarterly_grades
            .into_iter()
            .map(|qg| {
                let descriptor = qg
                    .transmuted_grade
                    .map(|t| deped_weights::get_descriptor(t).to_string());
                GradeSummaryRow {
                    student_id: qg.student_id.to_string(),
                    student_name: student_name_map
                        .get(&qg.student_id)
                        .cloned()
                        .unwrap_or_else(|| "Unknown".to_string()),
                    ww_weighted: qg.ww_weighted,
                    pt_weighted: qg.pt_weighted,
                    qa_weighted: qg.qa_weighted,
                    initial_grade: qg.initial_grade,
                    transmuted_grade: qg.transmuted_grade,
                    descriptor,
                    is_complete: qg.is_complete,
                }
            })
            .collect();

        Ok(GradeSummaryResponse {
            class_id: class_id.to_string(),
            quarter,
            ww_weight: config.ww_weight,
            pt_weight: config.pt_weight,
            qa_weight: config.qa_weight,
            students,
        })
    }
}

/// Compute percentage and weighted score for a single component.
fn compute_component(
    items: &[&::entity::grade_items::Model],
    score_map: &std::collections::HashMap<Uuid, f64>,
    weight: f64,
) -> (f64, f64) {
    let mut sum_scores = 0.0;
    let mut sum_total = 0.0;

    for item in items {
        if let Some(&score) = score_map.get(&item.id) {
            sum_scores += score;
            sum_total += item.total_points;
        } else {
            // Item with no score: still count total_points for denominator
            sum_total += item.total_points;
        }
    }

    if sum_total <= 0.0 {
        return (0.0, 0.0);
    }

    let percentage = (sum_scores / sum_total) * 100.0;
    let weighted = percentage * (weight / 100.0);
    (percentage, weighted)
}
