use serde::{Deserialize, Serialize};

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateTosRequest {
    pub title: String,
    pub grading_period_number: i32,
    pub classification_mode: String,
    pub total_items: i32,
    pub time_unit: Option<String>,
    pub easy_percentage: Option<f64>,
    pub medium_percentage: Option<f64>,
    pub hard_percentage: Option<f64>,
    pub remembering_percentage: Option<f64>,
    pub understanding_percentage: Option<f64>,
    pub applying_percentage: Option<f64>,
    pub analyzing_percentage: Option<f64>,
    pub evaluating_percentage: Option<f64>,
    pub creating_percentage: Option<f64>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateTosRequest {
    pub title: Option<String>,
    pub classification_mode: Option<String>,
    pub total_items: Option<i32>,
    pub time_unit: Option<String>,
    pub easy_percentage: Option<f64>,
    pub medium_percentage: Option<f64>,
    pub hard_percentage: Option<f64>,
    pub remembering_percentage: Option<f64>,
    pub understanding_percentage: Option<f64>,
    pub applying_percentage: Option<f64>,
    pub analyzing_percentage: Option<f64>,
    pub evaluating_percentage: Option<f64>,
    pub creating_percentage: Option<f64>,
}

#[derive(Debug, Deserialize)]
pub struct CreateCompetencyRequest {
    pub competency_code: Option<String>,
    pub competency_text: String,
    pub time_units_taught: i32,
    pub order_index: Option<i32>,
    pub easy_count: Option<i32>,
    pub medium_count: Option<i32>,
    pub hard_count: Option<i32>,
    pub remembering_count: Option<i32>,
    pub understanding_count: Option<i32>,
    pub applying_count: Option<i32>,
    pub analyzing_count: Option<i32>,
    pub evaluating_count: Option<i32>,
    pub creating_count: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateCompetencyRequest {
    pub competency_code: Option<String>,
    pub competency_text: Option<String>,
    pub time_units_taught: Option<i32>,
    pub order_index: Option<i32>,
    pub easy_count: Option<Option<i32>>,
    pub medium_count: Option<Option<i32>>,
    pub hard_count: Option<Option<i32>>,
    pub remembering_count: Option<Option<i32>>,
    pub understanding_count: Option<Option<i32>>,
    pub applying_count: Option<Option<i32>>,
    pub analyzing_count: Option<Option<i32>>,
    pub evaluating_count: Option<Option<i32>>,
    pub creating_count: Option<Option<i32>>,
}

#[derive(Debug, Deserialize)]
pub struct BulkAddCompetenciesRequest {
    pub competencies: Vec<CreateCompetencyRequest>,
}

#[derive(Debug, Deserialize)]
pub struct MelcsSearchQuery {
    pub subject: Option<String>,
    pub grade_level: Option<String>,
    pub quarter: Option<i32>,
    pub q: Option<String>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct TosResponse {
    pub id: String,
    pub class_id: String,
    pub grading_period_number: i32,
    pub title: String,
    pub classification_mode: String,
    pub total_items: i32,
    pub time_unit: String,
    pub easy_percentage: f64,
    pub medium_percentage: f64,
    pub hard_percentage: f64,
    pub remembering_percentage: f64,
    pub understanding_percentage: f64,
    pub applying_percentage: f64,
    pub analyzing_percentage: f64,
    pub evaluating_percentage: f64,
    pub creating_percentage: f64,
    pub competencies: Vec<CompetencyResponse>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct CompetencyResponse {
    pub id: String,
    pub competency_code: Option<String>,
    pub competency_text: String,
    pub time_units_taught: i32,
    pub order_index: i32,
    pub easy_count: Option<i32>,
    pub medium_count: Option<i32>,
    pub hard_count: Option<i32>,
    pub remembering_count: Option<i32>,
    pub understanding_count: Option<i32>,
    pub applying_count: Option<i32>,
    pub analyzing_count: Option<i32>,
    pub evaluating_count: Option<i32>,
    pub creating_count: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct TosListResponse {
    pub items: Vec<TosResponse>,
}

#[derive(Debug, Serialize)]
pub struct MelcSearchResponse {
    pub melcs: Vec<MelcEntry>,
}

#[derive(Debug, Serialize)]
pub struct MelcEntry {
    pub id: i64,
    pub subject: String,
    pub grade_level: String,
    pub quarter: Option<i32>,
    pub competency_code: String,
    pub competency_text: String,
    pub domain: Option<String>,
}
