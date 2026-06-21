use serde::{Deserialize, Serialize};

/// CSV row for school history import.
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SchoolHistoryCsvRow {
    pub username: Option<String>,
    pub full_name: Option<String>,
    pub school_name: Option<String>,
    pub school_id: Option<String>,
    pub grade_level: Option<String>,
    pub school_year: Option<String>,
    pub section: Option<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>,
    pub record_type: Option<String>,
}

/// CSV row for previous subjects import.
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SubjectsCsvRow {
    pub username: Option<String>,
    pub full_name: Option<String>,
    pub school_name: Option<String>,
    pub school_year: Option<String>,
    pub subject_name: Option<String>,
    pub subject_group: Option<String>,
    pub term_type: Option<String>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
    pub term1_grade: Option<i32>,
    pub term2_grade: Option<i32>,
    pub term3_grade: Option<i32>,
    pub term4_grade: Option<i32>,
}

/// CSV row for previous attendance import.
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AttendanceCsvRow {
    pub username: Option<String>,
    pub full_name: Option<String>,
    pub school_name: Option<String>,
    pub school_year: Option<String>,
    pub month: Option<String>,
    pub school_days: Option<i32>,
    pub days_present: Option<i32>,
}

/// Query param for history type.
#[derive(Debug, Deserialize)]
pub struct HistoryTypeQuery {
    #[serde(rename = "type")]
    pub history_type: String,
}

// Re-export shared types from admin module
pub use crate::modules::admin::import_schema::{
    ImportRequest, ImportResultResponse, PreviewResponse, PreviewRowResponse,
};
