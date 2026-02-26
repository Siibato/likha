use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq)]
#[sea_orm(table_name = "sync_cursors")]
pub struct Model {
    #[sea_orm(primary_key, column_type = "String(StringLen::None)")]
    pub id: String,
    #[sea_orm(column_type = "String(StringLen::None)")]
    pub user_id: String,
    #[sea_orm(column_type = "String(StringLen::None)")]
    pub entity_type: String,
    pub offset: i64,
    pub created_at: DateTime,
    pub expires_at: DateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
