use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq)]
#[sea_orm(table_name = "sync_conflicts")]
pub struct Model {
    #[sea_orm(primary_key, column_type = "String(StringLen::None)")]
    pub id: String,
    #[sea_orm(column_type = "String(StringLen::None)")]
    pub user_id: String,
    #[sea_orm(column_type = "String(StringLen::None)")]
    pub entity_type: String,
    #[sea_orm(column_type = "String(StringLen::None)")]
    pub entity_id: String,
    pub client_data: Option<String>,
    pub server_data: Option<String>,
    pub client_updated_at: Option<DateTime>,
    pub server_updated_at: Option<DateTime>,
    pub resolution: Option<String>,
    pub resolved_at: Option<DateTime>,
    pub created_at: DateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
