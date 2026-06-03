use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::SchoolSettingsResponse;
use crate::utils::AppResult;

pub async fn get_school_settings(repo: &SetupRepository) -> AppResult<SchoolSettingsResponse> {
    let row = repo.get_settings().await?;
    Ok(SchoolSettingsResponse {
        school_code: row.school_code,
        school_name: row.school_name,
        school_region: row.school_region,
        school_division: row.school_division,
        school_year: row.school_year,
    })
}
