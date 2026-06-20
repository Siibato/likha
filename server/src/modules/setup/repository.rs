use sea_orm::DatabaseConnection;

use crate::modules::setup::repository_operations as ops;
use crate::utils::AppResult;
use ::entity::school_settings;

pub struct SetupRepository {
    db: DatabaseConnection,
}

impl SetupRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn get_settings(&self) -> AppResult<school_settings::Model> {
        ops::get_settings(&self.db).await
    }

    pub async fn insert_settings(&self, default_code: String) -> AppResult<school_settings::Model> {
        ops::insert_settings(&self.db, default_code).await
    }

    pub async fn update_settings(
        &self,
        school_code: Option<String>,
        school_name: Option<Option<String>>,
        school_region: Option<Option<String>>,
        school_division: Option<Option<String>>,
        school_year: Option<Option<String>>,
        school_district: Option<Option<String>>,
        school_head_name: Option<Option<String>>,
        school_head_position: Option<Option<String>>,
    ) -> AppResult<school_settings::Model> {
        ops::update_settings(&self.db, school_code, school_name, school_region, school_division, school_year, school_district, school_head_name, school_head_position).await
    }
}
