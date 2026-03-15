use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "assessments")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub time_limit_minutes: i32,
    pub open_at: chrono::NaiveDateTime,
    pub close_at: chrono::NaiveDateTime,
    pub show_results_immediately: bool,
    pub results_released: bool,
    pub is_published: bool,
    pub order_index: i32,
    pub total_points: i32,
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
    #[sea_orm(has_many = "super::assessment_questions::Entity")]
    Questions,
    #[sea_orm(has_many = "super::assessment_submissions::Entity")]
    Submissions,
}

impl Related<super::classes::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Class.def()
    }
}

impl Related<super::assessment_questions::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Questions.def()
    }
}

impl Related<super::assessment_submissions::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Submissions.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
