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
            ("assessment", "publish" | "release_results") => {
                if user_role != "teacher" && user_role != "admin" {
                    return Err(AppError::Forbidden(
                        "Only teachers can publish assessments or release results".to_string(),
                    ));
                }
                Ok(())
            }
            ("assessment_submission", "create" | "save_answers" | "submit") => {
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can submit assessments".to_string(),
                    ));
                }
                Ok(())
            }
            ("assessment_submission", "override_answer") => {
                if user_role != "teacher" && user_role != "admin" {
                    return Err(AppError::Forbidden(
                        "Only teachers can override assessment answers".to_string(),
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
            ("assignment", "publish") => {
                if user_role != "teacher" && user_role != "admin" {
                    return Err(AppError::Forbidden(
                        "Only teachers can publish assignments".to_string(),
                    ));
                }
                Ok(())
            }
            ("assignment_submission", "create" | "submit") => {
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can submit assignments".to_string(),
                    ));
                }
                Ok(())
            }
            ("assignment_submission", "grade" | "update") => {
                if user_role != "teacher" && user_role != "admin" {
                    return Err(AppError::Forbidden(
                        "Only teachers can grade or return assignment submissions".to_string(),
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
            ("question", "create" | "update" | "delete") => {
                if user_role != "teacher" {
                    return Err(AppError::Forbidden(
                        "Only teachers can create/update/delete questions".to_string(),
                    ));
                }
                Ok(())
            }
            ("admin_user", "create" | "update" | "delete") => Ok(()),
            ("class", "add_enrollment" | "remove_enrollment") => {
                if let Some(class_id) = class_id {
                    self.entitlement_repo
                        .assert_can_modify_class(user_id, user_role, class_id)
                        .await?;
                }
                Ok(())
            }
            ("submission_file", "delete") => {
                if user_role != "student" {
                    return Err(AppError::Forbidden(
                        "Only students can delete submission files".to_string(),
                    ));
                }
                Ok(())
            }
            ("material_file", "delete") => {
                if user_role != "teacher" && user_role != "admin" {
                    return Err(AppError::Forbidden(
                        "Only teachers can delete material files".to_string(),
                    ));
                }
                Ok(())
            }
            ("grade_config", _) | ("grade_item", _) | ("grade_score", _) => {
                if user_role != "teacher" && user_role != "admin" {
                    return Err(AppError::Forbidden(
                        "Only teachers can modify grading data".to_string(),
                    ));
                }
                Ok(())
            }
            _ => {
                Err(AppError::BadRequest(format!(
                    "Unknown operation: {} on {}",
                    operation_type, entity_type
                )))
            }
        }
    }
}