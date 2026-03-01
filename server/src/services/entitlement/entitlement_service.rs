use crate::db::repositories::entitlement_repository::EntitlementRepository;
use crate::db::repositories::manifest_repository::ManifestRepository;
pub struct EntitlementService {
    pub entitlement_repo: EntitlementRepository,
    pub manifest_repo: ManifestRepository,
}

impl EntitlementService {
    pub fn new(
        entitlement_repo: EntitlementRepository,
        manifest_repo: ManifestRepository,
    ) -> Self {
        Self {
            entitlement_repo,
            manifest_repo,
        }
    }
}