use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "table_of_specifications")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub class_id: Uuid,
    pub quarter: i32,
    pub title: String,
    pub classification_mode: String,
    pub total_items: i32,
    pub time_unit: String,
    pub easy_percentage: f64,
    pub medium_percentage: f64,
    pub hard_percentage: f64,
    pub remembering_percentage: f64,
    pub understanding_percentage: f64,
    pub applying_percentage: f64,
    pub analyzing_percentage: f64,
    pub evaluating_percentage: f64,
    pub creating_percentage: f64,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
