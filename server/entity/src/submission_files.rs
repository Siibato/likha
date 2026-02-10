use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "submission_files")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub submission_id: Uuid,
    pub file_name: String,
    pub file_type: String,
    pub file_size: i64,
    #[serde(skip)]
    pub file_data: Vec<u8>,
    pub uploaded_at: chrono::NaiveDateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::assignment_submissions::Entity",
        from = "Column::SubmissionId",
        to = "super::assignment_submissions::Column::Id"
    )]
    Submission,
}

impl Related<super::assignment_submissions::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Submission.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
