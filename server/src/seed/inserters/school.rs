use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};

use crate::seed::specs::SchoolDetailsSpec;
use crate::utils::AppError;
use ::entity::school_details;

pub async fn insert_school_details(
    db: &DatabaseConnection,
    spec: &SchoolDetailsSpec,
) -> Result<(), AppError> {
    if let Some(existing) = school_details::Entity::find_by_id(spec.id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?
    {
        let mut model: school_details::ActiveModel = existing.into();
        model.school_code = Set(spec.school_code.clone());
        model.school_name = Set(spec.school_name.clone());
        model.school_region = Set(spec.school_region.clone());
        model.school_division = Set(spec.school_division.clone());
        model.school_year = Set(spec.school_year.clone());
        model.school_district = Set(spec.school_district.clone());
        model.school_head_name = Set(spec.school_head_name.clone());
        model.school_head_position = Set(spec.school_head_position.clone());
        model.updated_at = Set(spec.updated_at);
        model
            .update(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    } else {
        let model = school_details::ActiveModel {
            id: Set(spec.id),
            school_code: Set(spec.school_code.clone()),
            school_name: Set(spec.school_name.clone()),
            school_region: Set(spec.school_region.clone()),
            school_division: Set(spec.school_division.clone()),
            school_year: Set(spec.school_year.clone()),
            school_district: Set(spec.school_district.clone()),
            school_head_name: Set(spec.school_head_name.clone()),
            school_head_position: Set(spec.school_head_position.clone()),
            updated_at: Set(spec.updated_at),
        };
        model
            .insert(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }
    Ok(())
}
