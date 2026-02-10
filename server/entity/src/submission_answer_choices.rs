use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "submission_answer_choices")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub submission_answer_id: Uuid,
    pub choice_id: Uuid,
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
        belongs_to = "super::question_choices::Entity",
        from = "Column::ChoiceId",
        to = "super::question_choices::Column::Id"
    )]
    Choice,
}

impl Related<super::submission_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::SubmissionAnswer.def()
    }
}

impl Related<super::question_choices::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Choice.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
