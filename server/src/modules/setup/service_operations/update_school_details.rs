use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::{SchoolDetailsResponse, UpdateSchoolDetailsRequest};
use crate::utils::AppResult;

pub async fn update_school_details(
    repo: &SetupRepository,
    request: UpdateSchoolDetailsRequest,
) -> AppResult<SchoolDetailsResponse> {
    let updated = repo
        .update_settings(
            None,
            Some(Some(request.school_name)),
            request.school_region.map(Some),
            request.school_division.map(Some),
            request.school_year.map(Some),
            request.school_district.map(Some),
            request.school_head_name.map(Some),
            request.school_head_position.map(Some),
        )
        .await?;

    Ok(SchoolDetailsResponse {
        school_code: updated.school_code,
        school_name: updated.school_name,
        school_region: updated.school_region,
        school_division: updated.school_division,
        school_year: updated.school_year,
        school_district: updated.school_district,
        school_head_name: updated.school_head_name,
        school_head_position: updated.school_head_position,
    })
}
