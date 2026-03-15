use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "learning_materials")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub content_text: Option<String>,
    pub order_index: i32,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::classes::Entity",
        from = "Column::ClassId",
        to = "super::classes::Column::Id"
    )]
    Class,
    #[sea_orm(has_many = "super::material_files::Entity")]
    Files,
}

impl Related<super::classes::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Class.def()
    }
}

impl Related<super::material_files::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Files.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
