use uuid::Uuid;
use crate::modules::tos::schema::*;
use crate::utils::{AppError, AppResult};

impl crate::modules::tos::service::TosService {
    pub async fn create_tos(
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
        request: CreateTosRequest,
        client_id: Option<Uuid>,
    ) -> AppResult<TosResponse> {
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if request.classification_mode != "blooms" && request.classification_mode != "difficulty" {
            return Err(AppError::BadRequest(
                "classification_mode must be 'blooms' or 'difficulty'".to_string(),
            ));
        }

        let max_terms = crate::modules::grading::helpers::term_count::term_count("term") as i32;
        if !(1..=max_terms).contains(&request.term_number) {
            return Err(AppError::BadRequest(format!("term_number must be between 1 and {}", max_terms)));
        }

        let time_unit = request.time_unit.as_deref().unwrap_or("days");
        if time_unit != "days" && time_unit != "hours" {
            return Err(AppError::BadRequest(
                "time_unit must be 'days' or 'hours'".to_string(),
            ));
        }

        let easy_pct = request.easy_percentage.unwrap_or(50.0);
        let medium_pct = request.medium_percentage.unwrap_or(30.0);
        let hard_pct = request.hard_percentage.unwrap_or(20.0);
        let remembering_pct = request.remembering_percentage.unwrap_or(16.67);
        let understanding_pct = request.understanding_percentage.unwrap_or(16.67);
        let applying_pct = request.applying_percentage.unwrap_or(16.67);
        let analyzing_pct = request.analyzing_percentage.unwrap_or(16.67);
        let evaluating_pct = request.evaluating_percentage.unwrap_or(16.67);
        let creating_pct = request.creating_percentage.unwrap_or(16.67);

        let id = client_id.unwrap_or_else(Uuid::new_v4);
        if let Some(ref inv) = self.invalidator {
            inv.invalidate_tos_list(class_id).await;
        }

        let tos = self.tos_repo
            .create_tos(
                id,
                class_id,
                request.term_number,
                &request.title,
                &request.classification_mode,
                request.total_items,
                time_unit,
                easy_pct,
                medium_pct,
                hard_pct,
                remembering_pct,
                understanding_pct,
                applying_pct,
                analyzing_pct,
                evaluating_pct,
                creating_pct,
            )
            .await?;

        Ok(TosResponse {
            id: tos.id.to_string(),
            class_id: tos.class_id.to_string(),
            term_number: tos.term_number,
            title: tos.title,
            classification_mode: tos.classification_mode,
            total_items: tos.total_items,
            time_unit: tos.time_unit,
            easy_percentage: tos.easy_percentage,
            medium_percentage: tos.medium_percentage,
            hard_percentage: tos.hard_percentage,
            remembering_percentage: tos.remembering_percentage,
            understanding_percentage: tos.understanding_percentage,
            applying_percentage: tos.applying_percentage,
            analyzing_percentage: tos.analyzing_percentage,
            evaluating_percentage: tos.evaluating_percentage,
            creating_percentage: tos.creating_percentage,
            competencies: vec![],
            created_at: tos.created_at.to_string(),
            updated_at: tos.updated_at.to_string(),
        })
    }
}
