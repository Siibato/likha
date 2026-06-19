use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "learner_details")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    #[sea_orm(unique)]
    pub user_id: Uuid,
    pub lrn: Option<String>,
    pub age: Option<i32>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub birthdate: Option<chrono::NaiveDate>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub father_name: Option<String>,
    pub mother_name: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub date_admitted: Option<chrono::NaiveDate>,
    pub admitted_to_grade: Option<String>,
    pub created_at: chrono::NaiveDateTime,
    pub updated_at: chrono::NaiveDateTime,
    pub deleted_at: Option<chrono::NaiveDateTime>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::users::Entity",
        from = "Column::UserId",
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
