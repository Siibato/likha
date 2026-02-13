use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "material_files")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub material_id: Uuid,
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
        belongs_to = "super::learning_materials::Entity",
        from = "Column::MaterialId",
        to = "super::learning_materials::Column::Id"
    )]
    Material,
}

impl Related<super::learning_materials::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Material.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
