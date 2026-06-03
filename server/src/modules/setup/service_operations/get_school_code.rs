use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::ShortCodeResponse;
use crate::utils::AppResult;

pub async fn get_school_code(repo: &SetupRepository) -> AppResult<ShortCodeResponse> {
    let row = repo.get_settings().await?;
    Ok(ShortCodeResponse {
        code: row.school_code,
    })
}
