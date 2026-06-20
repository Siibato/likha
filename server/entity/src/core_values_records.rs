use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "core_values_records")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub student_id: Uuid,
    pub class_id: Uuid,
    pub school_year: String,
    pub grading_period_number: i32,
    pub core_value: String,
    pub behavior_statement: String,
    pub marking: String,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::StudentId",
        to = "super::users::Column::Id"
    )]
    Student,
    #[sea_orm(
        belongs_to = "super::classes::Entity",
        from = "Column::ClassId",
        to = "super::classes::Column::Id"
    )]
    Class,
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Student.def()
    }
}

impl Related<super::classes::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Class.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
