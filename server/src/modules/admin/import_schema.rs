use serde::{Deserialize, Serialize};

/// CSV row for student bulk import.
/// All fields are optional except username, first_name, last_name (validated at preview time).
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct StudentCsvRow {
    pub username: Option<String>,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub lrn: Option<String>,
    /// Deprecated - retained only to emit validation errors when present.
    pub age: Option<String>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub birthdate: Option<String>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub father_name: Option<String>,
    pub father_contact: Option<String>,
    pub mother_name: Option<String>,
    pub mother_contact: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub date_admitted: Option<String>,
}

/// A single preview row with validation results.
#[derive(Debug, Serialize, Deserialize)]
pub struct PreviewRowResponse {
    pub row_index: usize,
    pub data: serde_json::Value,
    pub errors: Vec<String>,
    pub warnings: Vec<String>,
}

/// The full preview response containing all rows.
#[derive(Debug, Serialize, Deserialize)]
pub struct PreviewResponse {
    pub rows: Vec<PreviewRowResponse>,
}

/// Request body for the final import step — an array of validated row data.
#[derive(Debug, Deserialize)]
pub struct ImportRequest {
    pub rows: Vec<serde_json::Value>,
}

/// Result of a bulk import operation.
#[derive(Debug, Serialize)]
pub struct ImportResultResponse {
    pub imported: usize,
    pub errors: Vec<String>,
}
