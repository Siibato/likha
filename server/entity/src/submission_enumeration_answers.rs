use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "submission_enumeration_answers")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub submission_answer_id: Uuid,
    pub answer_text: String,
    pub matched_item_id: Option<Uuid>,
    pub is_auto_correct: Option<bool>,
    pub is_override_correct: Option<bool>,
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
        belongs_to = "super::enumeration_items::Entity",
        from = "Column::MatchedItemId",
        to = "super::enumeration_items::Column::Id"
    )]
    MatchedItem,
}

impl Related<super::submission_answers::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::SubmissionAnswer.def()
    }
}

impl Related<super::enumeration_items::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::MatchedItem.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
