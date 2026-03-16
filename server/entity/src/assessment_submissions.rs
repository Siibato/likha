use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "assessment_submissions")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub assessment_id: Uuid,
    pub user_id: Uuid,
    pub started_at: chrono::NaiveDateTime,
    pub submitted_at: Option<chrono::NaiveDateTime>,
    pub total_points: f64,
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
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::UserId",
        to = "super::users::Column::Id"
    )]
    User,
    #[sea_orm(has_many = "super::submission_answers::Entity")]
    Answers,
}

impl Related<super::assessments::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Assessment.def()
    }
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::User.def()
    }
}

impl Related<super::submission_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Answers.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
