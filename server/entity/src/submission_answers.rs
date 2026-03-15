use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "submission_answers")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub submission_id: Uuid,
    pub question_id: Uuid,
    pub points: f64,
    pub overridden_by: Option<Uuid>,
    pub overridden_at: Option<chrono::NaiveDateTime>,
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
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::OverriddenBy",
        to = "super::users::Column::Id"
    )]
    OverriddenByUser,
    #[sea_orm(has_many = "super::submission_answer_items::Entity")]
    AnswerItems,
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

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::OverriddenByUser.def()
    }
}

impl Related<super::submission_answer_items::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::AnswerItems.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
