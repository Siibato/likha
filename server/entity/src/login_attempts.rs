use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "login_attempts")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub username: String,
    pub ip_address: String,
    pub attempt_count: i32,
    pub first_attempt_at: chrono::NaiveDateTime,
    pub last_attempt_at: chrono::NaiveDateTime,
    pub locked_until: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl Related<super::users::Entity> for Entity {
    fn to() -> RelationDef {
        unreachable!()
    }
}

impl ActiveModelBehavior for ActiveModel {}
