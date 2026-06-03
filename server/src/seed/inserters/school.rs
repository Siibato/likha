use sea_orm::{ActiveModelTrait, DatabaseConnection, Set};

use crate::seed::specs::SchoolSettingsSpec;
use crate::utils::AppError;
use ::entity::school_settings;

pub async fn insert_school_settings(
    db: &DatabaseConnection,
    spec: &SchoolSettingsSpec,
) -> Result<(), AppError> {
    let model = school_settings::ActiveModel {
        id: Set(spec.id),
        school_code: Set(spec.school_code.clone()),
        school_name: Set(spec.school_name.clone()),
        school_region: Set(spec.school_region.clone()),
        school_division: Set(spec.school_division.clone()),
        school_year: Set(spec.school_year.clone()),
        updated_at: Set(spec.updated_at),
    };
    model.insert(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    Ok(())
}
