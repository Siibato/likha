use uuid::Uuid;
use md5;
use crate::utils::error::AppResult;
use crate::schema::class_schema::ClassMetadataResponse;

impl super::ClassService {
    pub async fn get_classes_metadata(
        &self,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<ClassMetadataResponse> {
        let (last_modified, count, etag) = match role {
            "teacher" => self.class_repo.get_metadata(user_id).await?,
            "student" => {
                let enrollments = self.class_repo.find_student_enrollments(user_id).await?;
                let count = enrollments.len();
                let etag = format!("{:x}", md5::compute(format!("student-{}-{}", user_id, count).as_bytes()));
                (chrono::Utc::now().naive_utc(), count, etag)
            }
            _ => return Err(crate::utils::error::AppError::Forbidden("Invalid role".to_string())),
        };

        Ok(ClassMetadataResponse {
            last_modified: last_modified.to_string(),
            record_count: count,
            etag,
        })
    }
}