use sea_orm::EntityTrait;
use uuid::Uuid;
use crate::modules::grading::schema::{GradeSummaryResponse, GradeSummaryRow};
use crate::utils::{AppError, AppResult};
use crate::modules::grading::helpers::deped_weights;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_grade_summary(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<GradeSummaryResponse> {
        let config = self
            .repo
            .get_config(class_id, grading_period_number)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(
                    "Grading config not set up for this class/period".to_string(),
                )
            })?;

        let period_grades_data = self.repo.get_all_for_class(class_id, grading_period_number).await?;

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

        let students = period_grades_data
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
                    initial_grade: qg.initial_grade,
                    transmuted_grade: qg.transmuted_grade,
                    descriptor,
                    is_locked: qg.is_locked,
                }
            })
            .collect();

        Ok(GradeSummaryResponse {
            class_id: class_id.to_string(),
            grading_period_number,
            ww_weight: config.ww_weight,
            pt_weight: config.pt_weight,
            qa_weight: config.qa_weight,
            students,
        })
    }
}
