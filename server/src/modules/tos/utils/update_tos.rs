use uuid::Uuid;
use crate::modules::tos::schema::*;
use crate::utils::{AppError, AppResult};

impl crate::modules::tos::service::TosService {
    pub async fn update_tos(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: UpdateTosRequest,
    ) -> AppResult<TosResponse> {
        let tos = self.tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if let Some(ref mode) = request.classification_mode {
            if mode != "blooms" && mode != "difficulty" {
                return Err(AppError::BadRequest(
                    "classification_mode must be 'blooms' or 'difficulty'".to_string(),
                ));
            }
        }

        if let Some(ref unit) = request.time_unit {
            if unit != "days" && unit != "hours" {
                return Err(AppError::BadRequest(
                    "time_unit must be 'days' or 'hours'".to_string(),
                ));
            }
        }

        self.tos_repo
            .update_tos(
                tos_id,
                request.title.as_deref(),
                request.classification_mode.as_deref(),
                request.total_items,
                request.time_unit.as_deref(),
                request.easy_percentage,
                request.medium_percentage,
                request.hard_percentage,
                request.remembering_percentage,
                request.understanding_percentage,
                request.applying_percentage,
                request.analyzing_percentage,
                request.evaluating_percentage,
                request.creating_percentage,
            )
            .await?;

        self.get_tos(tos_id).await
    }
}
