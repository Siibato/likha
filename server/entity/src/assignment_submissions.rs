use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "assignment_submissions")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub assignment_id: Uuid,
    pub student_id: Uuid,
    pub status: String,
    pub text_content: Option<String>,
    pub submitted_at: Option<chrono::NaiveDateTime>,
    pub points: Option<i32>,
    pub graded_by: Option<Uuid>,
    pub feedback: Option<String>,
    pub graded_at: Option<chrono::NaiveDateTime>,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::assignments::Entity",
        from = "Column::AssignmentId",
        to = "super::assignments::Column::Id"
    )]
    Assignment,
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::StudentId",
        to = "super::users::Column::Id"
    )]
    Student,
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::GradedBy",
        to = "super::users::Column::Id"
    )]
    GradedByUser,
    #[sea_orm(has_many = "super::submission_files::Entity")]
    Files,
}

impl Related<super::assignments::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Assignment.def()
    }
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Student.def()
    }
}

impl Related<super::submission_files::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Files.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
