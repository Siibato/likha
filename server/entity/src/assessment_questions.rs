use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "assessment_questions")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub assessment_id: Uuid,
    pub question_type: String,
    pub question_text: String,
    pub points: i32,
    pub order_index: i32,
    pub is_multi_select: bool,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::assessments::Entity",
        from = "Column::AssessmentId",
        to = "super::assessments::Column::Id"
    )]
    Assessment,
    #[sea_orm(has_many = "super::question_choices::Entity")]
    Choices,
    #[sea_orm(has_many = "super::question_correct_answers::Entity")]
    CorrectAnswers,
    #[sea_orm(has_many = "super::enumeration_items::Entity")]
    EnumerationItems,
}

impl Related<super::assessments::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Assessment.def()
    }
}

impl Related<super::question_choices::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Choices.def()
    }
}

impl Related<super::question_correct_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::CorrectAnswers.def()
    }
}

impl Related<super::enumeration_items::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::EnumerationItems.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
