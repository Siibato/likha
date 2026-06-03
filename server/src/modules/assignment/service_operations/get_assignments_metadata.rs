use uuid::Uuid;
use md5;
use crate::utils::AppResult;
use crate::modules::assignment::schema::*;
use crate::modules::assignment::repository::AssignmentRepository;

pub async fn get_assignments_metadata(
    assignment_repo: &AssignmentRepository,
    class_id: Uuid,
) -> AppResult<AssignmentMetadataResponse> {
    let assignments = assignment_repo.find_by_class_id(class_id).await?;
    let count = assignments.len();

    let last_modified = if count > 0 {
        assignments
            .iter()
            .map(|a| a.updated_at)
            .max()
            .unwrap_or_else(|| chrono::Utc::now().naive_utc())
    } else {
        chrono::Utc::now().naive_utc()
    };

    let etag_data = format!("{}-{}", count, last_modified);
    let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

    Ok(AssignmentMetadataResponse {
        last_modified: last_modified.to_string(),
        record_count: count,
        etag,
    })
}
