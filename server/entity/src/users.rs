use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "users")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    #[sea_orm(unique)]
    pub username: String,
    pub password_hash: Option<String>,
    pub full_name: String,
    pub role: String,
    pub account_status: String,
    pub is_active: bool,
    pub activated_at: Option<chrono::NaiveDateTime>,
    pub created_by: Option<Uuid>,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(has_many = "super::refresh_tokens::Entity")]
    RefreshTokens,
    #[sea_orm(has_many = "super::activity_logs::Entity")]
    ActivityLogs,
    #[sea_orm(has_many = "super::classes::Entity")]
    Classes,
    #[sea_orm(has_many = "super::class_enrollments::Entity")]
    ClassEnrollments,
}

impl Related<super::refresh_tokens::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::RefreshTokens.def()
    }
}

impl Related<super::activity_logs::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::ActivityLogs.def()
    }
}

impl Related<super::classes::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Classes.def()
    }
}

impl Related<super::class_enrollments::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::ClassEnrollments.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
