use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::class::schema::ClassMetadataResponse;
use crate::modules::class::repository::ClassRepository;

pub async fn get_classes_metadata(
    class_repo: &ClassRepository,
    user_id: Uuid,
    role: &str,
) -> AppResult<ClassMetadataResponse> {
    let (last_modified, count, etag) = match role {
        "teacher" => class_repo.get_metadata(user_id).await?,
        "student" => {
            let enrollments = class_repo.find_student_enrollments(user_id).await?;
            let count = enrollments.len();
            let etag = format!("{:x}", md5::compute(format!("student-{}-{}", user_id, count).as_bytes()));
            (chrono::Utc::now().naive_utc(), count, etag)
        }
        _ => return Err(AppError::Forbidden("Invalid role".to_string())),
    };

    Ok(ClassMetadataResponse {
        last_modified: last_modified.to_string(),
        record_count: count,
        etag,
    })
}
