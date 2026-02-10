use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "submission_answers")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub submission_id: Uuid,
    pub question_id: Uuid,
    pub answer_text: Option<String>,
    pub is_auto_correct: Option<bool>,
    pub is_override_correct: Option<bool>,
    pub points_awarded: f64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::assessment_submissions::Entity",
        from = "Column::SubmissionId",
        to = "super::assessment_submissions::Column::Id"
    )]
    Submission,
    #[sea_orm(
        belongs_to = "super::assessment_questions::Entity",
        from = "Column::QuestionId",
        to = "super::assessment_questions::Column::Id"
    )]
    Question,
    #[sea_orm(has_many = "super::submission_answer_choices::Entity")]
    SelectedChoices,
    #[sea_orm(has_many = "super::submission_enumeration_answers::Entity")]
    EnumerationAnswers,
}

impl Related<super::assessment_submissions::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Submission.def()
    }
}

impl Related<super::assessment_questions::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Question.def()
    }
}

impl Related<super::submission_answer_choices::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::SelectedChoices.def()
    }
}

impl Related<super::submission_enumeration_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::EnumerationAnswers.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
