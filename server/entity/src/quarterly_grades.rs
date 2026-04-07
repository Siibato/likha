use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "quarterly_grades")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub class_id: Uuid,
    pub student_id: Uuid,
    pub quarter: i32,
    pub ww_percentage: Option<f64>,
    pub pt_percentage: Option<f64>,
    pub qa_percentage: Option<f64>,
    pub ww_weighted: Option<f64>,
    pub pt_weighted: Option<f64>,
    pub qa_weighted: Option<f64>,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub is_complete: bool,
    pub computed_at: Option<chrono::NaiveDateTime>,
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
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::StudentId",
        to = "super::users::Column::Id"
    )]
    Student,
}

impl Related<super::classes::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Class.def()
    }
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Student.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
