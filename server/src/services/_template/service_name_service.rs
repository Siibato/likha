use sea_orm::DatabaseConnection;
use crate::db::repositories::service_name_repository::ServiceNameRepository;

pub struct ServiceName {
    pub repo: ServiceNameRepository,
    pub db: DatabaseConnection,
    // Add other dependencies as needed
}

impl ServiceName {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            repo: ServiceNameRepository::new(db.clone()),
            db,
        }
    }
}
