use sea_orm::DatabaseConnection;
use crate::db::repositories::manifest_repository::ManifestRepository;

pub struct SyncRepository {
    pub db: DatabaseConnection,
}

impl SyncRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub fn manifest(&self) -> ManifestRepository {
        ManifestRepository::new(self.db.clone())
    }
}
