use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::VerifyResponse;
use crate::utils::{AppError, AppResult};

pub async fn verify_code(repo: &SetupRepository, code: &str) -> AppResult<VerifyResponse> {
    let row = repo.get_settings().await?;
    if code.to_uppercase() == row.school_code.to_uppercase() {
        Ok(VerifyResponse {
            school_name: row.school_name,
        })
    } else {
        Err(AppError::Forbidden("Invalid school code".to_string()))
    }
}
