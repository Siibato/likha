use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::{SchoolSettingsResponse, UpdateSchoolSettingsRequest};
use crate::utils::AppResult;

pub async fn update_school_settings(
    repo: &SetupRepository,
    request: UpdateSchoolSettingsRequest,
) -> AppResult<SchoolSettingsResponse> {
    let updated = repo
        .update_settings(
            None,
            Some(Some(request.school_name)),
            request.school_region.map(Some),
            request.school_division.map(Some),
            request.school_year.map(Some),
        )
        .await?;

    Ok(SchoolSettingsResponse {
        school_code: updated.school_code,
        school_name: updated.school_name,
        school_region: updated.school_region,
        school_division: updated.school_division,
        school_year: updated.school_year,
    })
}
