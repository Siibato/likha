use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "previous_school_subjects")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub student_id: Uuid,
    pub school_history_id: Uuid,
    pub subject_name: String,
    pub subject_group: Option<String>,
    pub term_type: String,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
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
        belongs_to = "super::student_school_history::Entity",
        from = "Column::SchoolHistoryId",
        to = "super::student_school_history::Column::Id"
    )]
    SchoolHistory,
    #[sea_orm(
        has_many = "super::previous_school_term_grades::Entity",
        from = "Column::Id",
        to = "super::previous_school_term_grades::Column::SubjectId"
    )]
    TermGrades,
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Student.def()
    }
}

impl Related<super::student_school_history::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::SchoolHistory.def()
    }
}

impl Related<super::previous_school_term_grades::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::TermGrades.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
