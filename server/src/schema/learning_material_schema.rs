use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateMaterialRequest {
    pub title: String,
    pub description: Option<String>,
    pub content_text: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateMaterialRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub content_text: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ReorderMaterialRequest {
    pub new_order_index: i32,
}

#[derive(Debug, Deserialize)]
pub struct ReorderMaterialsRequest {
    pub material_ids: Vec<Uuid>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct MaterialResponse {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub content_text: Option<String>,
    pub order_index: i32,
    pub file_count: usize,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct MaterialListResponse {
    pub materials: Vec<MaterialResponse>,
}

#[derive(Debug, Serialize)]
pub struct MaterialDetailResponse {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub content_text: Option<String>,
    pub order_index: i32,
    pub files: Vec<FileMetadataResponse>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct FileMetadataResponse {
    pub id: Uuid,
    pub file_name: String,
    pub file_type: String,
    pub file_size: i64,
    pub uploaded_at: String,
}

// ===== METADATA SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct LearningMaterialMetadataResponse {
    pub last_modified: String,
    pub record_count: usize,
    pub etag: String,
}
