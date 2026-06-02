use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::VerifyResponse;
use crate::utils::AppResult;

pub async fn get_school_info(repo: &SetupRepository) -> AppResult<VerifyResponse> {
    let row = repo.get_settings().await?;
    Ok(VerifyResponse {
        school_name: row.school_name,
    })
}
