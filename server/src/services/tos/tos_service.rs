use sea_orm::DatabaseConnection;

use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;

pub struct TosService {
    pub tos_repo: TosRepository,
    pub class_repo: ClassRepository,
}

impl TosService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            tos_repo: TosRepository::new(db.clone()),
            class_repo: ClassRepository::new(db),
        }
    }
}
