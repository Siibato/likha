use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "enumeration_item_answers")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub enumeration_item_id: Uuid,
    pub answer_text: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::enumeration_items::Entity",
        from = "Column::EnumerationItemId",
        to = "super::enumeration_items::Column::Id"
    )]
    EnumerationItem,
}

impl Related<super::enumeration_items::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::EnumerationItem.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
