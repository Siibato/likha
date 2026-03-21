use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "grade_items")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub component: String,
    pub quarter: i32,
    pub total_points: f64,
    pub is_departmental_exam: bool,
    pub source_type: String,
    pub source_id: Option<String>,
    pub order_index: i32,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::classes::Entity",
        from = "Column::ClassId",
        to = "super::classes::Column::Id"
    )]
    Class,
    #[sea_orm(has_many = "super::grade_scores::Entity")]
    Scores,
}

impl Related<super::classes::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Class.def()
    }
}

impl Related<super::grade_scores::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Scores.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
