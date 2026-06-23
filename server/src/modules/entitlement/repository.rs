use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::modules::entitlement::repository_operations as ops;
use crate::utils::AppResult;

/// Verifies user authorization and scopes queries by entitlement
pub struct EntitlementRepository {
    db: DatabaseConnection,
}

impl EntitlementRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// Get all classes user is enrolled in (student) or teaches (teacher)
    /// Admin can access all classes
    pub async fn get_user_accessible_classes(
        &self,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<Vec<Uuid>> {
        ops::get_user_accessible_classes(&self.db, user_id, user_role).await
    }

    /// Check if user teaches a specific class
    pub async fn is_teacher_of_class(&self, teacher_id: Uuid, class_id: Uuid) -> AppResult<bool> {
        ops::is_teacher_of_class(&self.db, teacher_id, class_id).await
    }

    /// Verify user can perform an action on an entity
    /// Returns error if not authorized
    pub async fn assert_can_modify_class(
        &self,
        user_id: Uuid,
        user_role: &str,
        class_id: Uuid,
    ) -> AppResult<()> {
        ops::assert_can_modify_class(&self.db, user_id, user_role, class_id).await
    }
}
