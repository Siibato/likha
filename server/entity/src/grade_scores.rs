use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "grade_scores")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub grade_item_id: Uuid,
    pub student_id: Uuid,
    pub score: Option<f64>,
    pub is_auto_populated: bool,
    pub override_score: Option<f64>,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::grade_items::Entity",
        from = "Column::GradeItemId",
        to = "super::grade_items::Column::Id"
    )]
    GradeItem,
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::StudentId",
        to = "super::users::Column::Id"
    )]
    Student,
}

impl Related<super::grade_items::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::GradeItem.def()
    }
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Student.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
