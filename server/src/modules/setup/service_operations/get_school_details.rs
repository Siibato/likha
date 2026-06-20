use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::SchoolDetailsResponse;
use crate::utils::AppResult;

pub async fn get_school_details(repo: &SetupRepository) -> AppResult<SchoolDetailsResponse> {
    let row = repo.get_settings().await?;
    Ok(SchoolDetailsResponse {
        school_code: row.school_code,
        school_name: row.school_name,
        school_region: row.school_region,
        school_division: row.school_division,
        school_year: row.school_year,
        school_district: row.school_district,
        school_head_name: row.school_head_name,
        school_head_position: row.school_head_position,
    })
}
