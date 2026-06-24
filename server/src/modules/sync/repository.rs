use crate::modules::sync::ManifestRepository;
use sea_orm::DatabaseConnection;

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
