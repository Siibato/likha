use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "answer_keys")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub question_id: Uuid,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::assessment_questions::Entity",
        from = "Column::QuestionId",
        to = "super::assessment_questions::Column::Id"
    )]
    Question,
    #[sea_orm(has_many = "super::answer_key_acceptable_answers::Entity")]
    AcceptableAnswers,
}

impl Related<super::assessment_questions::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Question.def()
    }
}

impl Related<super::answer_key_acceptable_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::AcceptableAnswers.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
