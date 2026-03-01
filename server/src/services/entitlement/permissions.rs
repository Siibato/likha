use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};

impl super::EntitlementService {
    pub async fn assert_can_sync_operation(
        &self,
        user_id: Uuid,
        user_role: &str,
        operation_type: &str,
        entity_type: &str,
        class_id: Option<Uuid>,
    ) -> AppResult<()> {
        match (entity_type, operation_type) {
            ("class", "create") => {
                if user_role == "student" {
                    return Err(AppError::Forbidden(
                        "Students cannot create classes".to_string(),
                    ));
                }
                Ok(())
            }
            ("class", "update" | "delete") => {
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("assessment", "create" | "update" | "delete") => {
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("assessment_submission", "create" | "update") => {
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can submit assessments".to_string(),
                    ));
                }
                Ok(())
            }
            ("assignment", "create" | "update" | "delete") => {
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("assignment_submission", "create" | "update") => {
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can submit assignments".to_string(),
                    ));
                }
                Ok(())
            }
            ("learning_material", "create" | "update" | "delete") => {
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("admin_user", "create" | "update" | "delete") => Ok(()),
            _ => {
                Err(AppError::BadRequest(format!(
                    "Unknown operation: {} on {}",
                    operation_type, entity_type
                )))
            }
        }
    }
}