use md5;
use crate::utils::error::AppResult;
use crate::schema::learning_material_schema::LearningMaterialMetadataResponse;

impl super::LearningMaterialService {
    pub async fn get_materials_metadata(&self) -> AppResult<LearningMaterialMetadataResponse> {
        let materials = self.material_repo.find_all().await?;
        let count = materials.len();

        let last_modified = if count > 0 {
            materials
                .iter()
                .map(|m| m.updated_at)
                .max()
                .unwrap_or_else(|| chrono::Utc::now().naive_utc())
        } else {
            chrono::Utc::now().naive_utc()
        };

        let etag_data = format!("{}-{}", count, last_modified);
        let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

        Ok(LearningMaterialMetadataResponse {
            last_modified: last_modified.to_string(),
            record_count: count,
            etag,
        })
    }
}