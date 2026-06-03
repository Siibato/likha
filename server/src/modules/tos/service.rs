use sea_orm::DatabaseConnection;

use crate::modules::class::repository::ClassRepository;
use crate::modules::tos::repository::TosRepository;

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
