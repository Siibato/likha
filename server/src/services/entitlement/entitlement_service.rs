use sea_orm::DatabaseConnection;
use crate::db::repositories::entitlement_repository::EntitlementRepository;
use crate::db::repositories::manifest_repository::ManifestRepository;

pub struct EntitlementService {
    pub entitlement_repo: EntitlementRepository,
    pub manifest_repo: ManifestRepository,
    pub db: DatabaseConnection,
}

impl EntitlementService {
    pub fn new(db: DatabaseConnection) -> Self {
        let db_clone = db.clone();
        Self {
            entitlement_repo: EntitlementRepository::new(db.clone()),
            manifest_repo: ManifestRepository::new(db),
            db: db_clone,
        }
    }
}