use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "classes")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub teacher_id: Uuid,
    pub is_archived: bool,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::TeacherId",
        to = "super::users::Column::Id"
    )]
    Teacher,
    #[sea_orm(has_many = "super::class_enrollments::Entity")]
    ClassEnrollments,
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Teacher.def()
    }
}

impl Related<super::class_enrollments::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::ClassEnrollments.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
