use std::collections::HashMap;
use futures::future::{join_all, try_join_all};
use sea_orm::EntityTrait;
use uuid::Uuid;
use crate::modules::grading::helpers::deped_weights;
use crate::modules::grading::schema::{
    AllGradeDataResponse, GradeItemResponse, GradeScoreResponse, GradeSummaryResponse,
    GradeSummaryRow, GradingConfigResponse,
};
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn get_all_grade_data(
        &self,
        class_id: Uuid,
        term_number: i32,
    ) -> AppResult<AllGradeDataResponse> {
        let (items_raw, config_opt, participants, term_grades_data) = tokio::try_join!(
            self.repo.get_items(class_id, term_number),
            self.repo.get_config(class_id, term_number),
            self.class_repo.find_participants_by_class_id(class_id, None),
            self.repo.get_all_for_class(class_id, term_number),
        )?;

        let items: Vec<GradeItemResponse> =
            items_raw.into_iter().map(GradeItemResponse::from).collect();

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
            (
                p.user_id,
                user.map(|u| format!("{}, {}", u.last_name, u.first_name))
                    .unwrap_or_else(|| "Unknown".to_string()),
            )
        });
        let name_pairs = join_all(name_futures).await;
        let student_name_map: HashMap<Uuid, String> =
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

        let summary = GradeSummaryResponse {
            class_id: class_id.to_string(),
            term_number: term_number,
            ww_weight: config.ww_weight,
            pt_weight: config.pt_weight,
            qa_weight: config.qa_weight,
            students,
        };

        let score_futures = items.iter().map(|item| async {
            let item_id = match Uuid::parse_str(&item.id) {
                Ok(id) => id,
                Err(_) => return Ok::<_, AppError>((item.id.clone(), vec![])),
            };
            let scores = self.repo.get_scores_by_item(item_id).await?;
            let result: Vec<GradeScoreResponse> =
                scores.into_iter().map(GradeScoreResponse::from).collect();
            Ok((item.id.clone(), result))
        });

        let scores_by_item: HashMap<String, Vec<_>> =
            try_join_all(score_futures).await?.into_iter().collect();

        Ok(AllGradeDataResponse {
            grade_items: items,
            grade_summary: summary,
            term_number,
            scores_by_item,
            config: Some(GradingConfigResponse::from(config)),
        })
    }
}
