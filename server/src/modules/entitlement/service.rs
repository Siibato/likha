use sea_orm::DatabaseConnection;

use crate::modules::entitlement::repository::EntitlementRepository;
use crate::modules::sync::ManifestRepository;

pub struct EntitlementService {
    pub entitlement_repo: EntitlementRepository,
    pub manifest_repo: ManifestRepository,
}

impl EntitlementService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            entitlement_repo: EntitlementRepository::new(db.clone()),
            manifest_repo: ManifestRepository::new(db),
        }
    }
}
