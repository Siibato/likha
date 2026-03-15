use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "submission_answer_items")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub submission_answer_id: Uuid,
    pub answer_key_id: Option<Uuid>,
    pub choice_id: Option<Uuid>,
    pub answer_text: Option<String>,
    pub is_correct: bool,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::submission_answers::Entity",
        from = "Column::SubmissionAnswerId",
        to = "super::submission_answers::Column::Id"
    )]
    SubmissionAnswer,
    #[sea_orm(
        belongs_to = "super::answer_keys::Entity",
        from = "Column::AnswerKeyId",
        to = "super::answer_keys::Column::Id"
    )]
    AnswerKey,
    #[sea_orm(
        belongs_to = "super::question_choices::Entity",
        from = "Column::ChoiceId",
        to = "super::question_choices::Column::Id"
    )]
    QuestionChoice,
}

impl Related<super::submission_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::SubmissionAnswer.def()
    }
}

impl Related<super::answer_keys::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::AnswerKey.def()
    }
}

impl Related<super::question_choices::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::QuestionChoice.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
