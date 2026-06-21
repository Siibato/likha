use futures::future::join_all;
use sea_orm::EntityTrait;
use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::{GradeSummaryResponse, GradeSummaryRow};
use crate::utils::{AppError, AppResult};
use crate::modules::grading::helpers::deped_weights;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_grade_summary(
        &self,
        class_id: Uuid,
        term_number: i32,
    ) -> AppResult<GradeSummaryResponse> {
        if let Some(ref cache) = self.cache {
            let key = CacheKey::GradeSummary(class_id, term_number).as_str();
            if let Some(cached) = cache.get::<GradeSummaryResponse>(&key).await {
                return Ok(cached);
            }
        }
        let (config_opt, term_grades_data, participants) = tokio::try_join!(
            self.repo.get_config(class_id, term_number),
            self.repo.get_all_for_class(class_id, term_number),
            self.class_repo.find_participants_by_class_id(class_id, None),
        )?;

        let config = config_opt.ok_or_else(|| {
            AppError::BadRequest(
                "Grading config not set up for this class/term".to_string(),
            )
        })?;

        let name_futures = participants.iter().map(|p| async move {
            let user = ::entity::users::Entity::find_by_id(p.user_id)
                .one(&self.db)
                .await
                .ok()
                .flatten();
            (p.user_id, user.map(|u| format!("{}, {}", u.last_name, u.first_name)).unwrap_or_else(|| "Unknown".to_string()))
        });
        let name_pairs = join_all(name_futures).await;
        let student_name_map: std::collections::HashMap<Uuid, String> =
            name_pairs.into_iter().collect();

        let mut students: Vec<GradeSummaryRow> = term_grades_data
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
        students.sort_by(|a, b| a.student_name.cmp(&b.student_name));

        let result = GradeSummaryResponse {
            class_id: class_id.to_string(),
            term_number,
            ww_weight: config.ww_weight,
            pt_weight: config.pt_weight,
            qa_weight: config.qa_weight,
            students,
        };
        if let Some(ref cache) = self.cache {
            let key = CacheKey::GradeSummary(class_id, term_number).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }
}
