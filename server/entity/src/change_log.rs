use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "change_log")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = true)]
    pub sequence: i64,
    #[sea_orm(unique)]
    pub id: Uuid,
    pub entity_type: String,
    pub entity_id: String,
    pub operation: String,
    pub performed_by: Uuid,
    pub payload: Option<String>,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::PerformedBy",
        to = "super::users::Column::Id"
    )]
    User,
}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::User.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
