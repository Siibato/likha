use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "tos_competencies")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub tos_id: Uuid,
    pub competency_code: Option<String>,
    pub competency_text: String,
    pub time_units_taught: i32,
    pub order_index: i32,
    pub easy_count: Option<i32>,
    pub medium_count: Option<i32>,
    pub hard_count: Option<i32>,
    pub remembering_count: Option<i32>,
    pub understanding_count: Option<i32>,
    pub applying_count: Option<i32>,
    pub analyzing_count: Option<i32>,
    pub evaluating_count: Option<i32>,
    pub creating_count: Option<i32>,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
