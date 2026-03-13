use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "answer_key_acceptable_answers")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub answer_key_id: Uuid,
    pub answer_text: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::answer_keys::Entity",
        from = "Column::AnswerKeyId",
        to = "super::answer_keys::Column::Id"
    )]
    AnswerKey,
}

impl Related<super::answer_keys::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::AnswerKey.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
