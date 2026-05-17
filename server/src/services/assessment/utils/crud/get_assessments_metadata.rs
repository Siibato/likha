use crate::utils::AppResult;
use crate::utils::fmt_utc;
use crate::schema::assessment_schema::*;
use md5;

impl crate::services::assessment::AssessmentService {
    pub async fn get_assessments_metadata(&self) -> AppResult<AssessmentMetadataResponse> {
        let assessments = self.assessment_repo.find_all().await?;
        let count = assessments.len();

        let last_modified = if count > 0 {
            assessments
                .iter()
                .map(|a| a.updated_at)
                .max()
                .unwrap_or_else(|| chrono::Utc::now().naive_utc())
        } else {
            chrono::Utc::now().naive_utc()
        };

        let etag_data = format!("{}-{}", count, last_modified);
        let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

        Ok(AssessmentMetadataResponse {
            last_modified: fmt_utc(last_modified),
            record_count: count,
            etag,
        })
    }
}
