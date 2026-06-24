use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

use crate::modules::grading::helpers::deped_weights::get_descriptor;
use crate::modules::student_records::schema::CoreValuesResponse;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct SetupGradingConfigRequest {
    pub grade_level: String,
    pub subject_group: String,
    pub school_year: String,
    pub semester: Option<i32>,
    pub ww_weight: Option<f64>,
    pub pt_weight: Option<f64>,
    pub qa_weight: Option<f64>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateGradingConfigRequest {
    pub term_number: i32,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
}

#[derive(Debug, Deserialize)]
pub struct CreateGradeItemRequest {
    pub id: Option<String>,
    pub title: String,
    pub component: String,
    pub term_number: Option<i32>,
    pub total_points: f64,
    pub source_type: Option<String>,
    pub source_id: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateGradeItemRequest {
    pub title: Option<String>,
    pub component: Option<String>,
    pub total_points: Option<f64>,
    pub order_index: Option<i32>,
    pub source_type: Option<String>,
    pub source_id: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct StudentScore {
    pub student_id: Uuid,
    pub score: f64,
}

#[derive(Debug, Deserialize)]
pub struct BulkUpdateScoresRequest {
    #[serde(default)]
    pub grade_item_id: String,
    pub scores: Vec<StudentScore>,
}

#[derive(Debug, Deserialize)]
pub struct OverrideScoreRequest {
    pub override_score: f64,
}

#[derive(Debug, Deserialize)]
pub struct TermQuery {
    pub term_number: Option<i32>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct GradingConfigResponse {
    pub id: String,
    pub class_id: String,
    pub term_number: Option<i32>,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradeItemResponse {
    pub id: String,
    pub class_id: String,
    pub title: String,
    pub component: String,
    pub term_number: Option<i32>,
    pub total_points: f64,
    pub source_type: String,
    pub source_id: Option<String>,
    pub order_index: i32,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub scores: Vec<GradeScoreResponse>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradeScoreResponse {
    pub id: String,
    pub grade_item_id: String,
    pub student_id: String,
    pub score: Option<f64>,
    pub is_auto_populated: bool,
    pub override_score: Option<f64>,
    pub effective_score: Option<f64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TermGradeResponse {
    pub id: String,
    pub class_id: String,
    pub student_id: String,
    pub term_number: i32,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub descriptor: Option<String>,
    pub is_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FinalGradeResponse {
    pub student_id: String,
    pub term_grades: Vec<TermGradeResponse>,
    pub final_grade: Option<f64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GradeSummaryRow {
    pub student_id: String,
    pub student_name: String,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub descriptor: Option<String>,
    pub is_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GradeSummaryResponse {
    pub class_id: String,
    pub term_number: i32,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
    pub students: Vec<GradeSummaryRow>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PresetInfo {
    pub key: String,
    pub label: String,
    pub ww: f64,
    pub pt: f64,
    pub qa: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DepEdPresetsResponse {
    pub presets: Vec<PresetInfo>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ClassGradingSetupResponse {
    pub class_id: String,
    pub grade_level: String,
    pub school_year: String,
    pub term_type: String,
    pub configs: Vec<GradingConfigResponse>,
}

// ===== GENERAL AVERAGE (GSA) SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct GeneralAverageResponse {
    pub class_id: String,
    pub students: Vec<StudentGeneralAverage>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StudentGeneralAverage {
    pub student_id: String,
    pub student_name: String,
    pub general_average: Option<i32>,
    pub subject_count: usize,
    pub subjects: Vec<SubjectGrade>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SubjectGrade {
    pub class_id: String,
    pub class_title: String,
    pub final_grade: Option<i32>,
}

// ===== SF9/SF10 SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf9AttendanceRecord {
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf9Response {
    pub student_id: String,
    pub student_name: String,
    pub grade_level: Option<String>,
    pub school_year: Option<String>,
    pub section: Option<String>,
    pub lrn: Option<String>,
    pub age: Option<i32>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub teacher_name: Option<String>,
    pub term_type: Option<String>,
    pub subjects: Vec<Sf9SubjectRow>,
    pub general_average: Option<Sf9TermAverages>,
    #[serde(default)]
    pub core_values: Vec<CoreValuesResponse>,
    #[serde(default)]
    pub attendance: Vec<Sf9AttendanceRecord>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf9SubjectRow {
    pub class_title: String,
    pub subject_group: Option<String>,
    pub term_grades: Vec<Option<i32>>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf9TermAverages {
    pub term_grades: Vec<Option<i32>>,
    pub final_average: Option<i32>,
    pub descriptor: Option<String>,
}

// ===== FROM CONVERSIONS =====

impl From<::entity::grade_record::Model> for GradingConfigResponse {
    fn from(m: ::entity::grade_record::Model) -> Self {
        Self {
            id: m.id.to_string(),
            class_id: m.class_id.to_string(),
            term_number: m.term_number,
            ww_weight: m.ww_weight,
            pt_weight: m.pt_weight,
            qa_weight: m.qa_weight,
        }
    }
}

impl From<::entity::grade_items::Model> for GradeItemResponse {
    fn from(m: ::entity::grade_items::Model) -> Self {
        Self {
            id: m.id.to_string(),
            class_id: m.class_id.to_string(),
            title: m.title,
            component: m.component,
            term_number: m.term_number,
            total_points: m.total_points,
            source_type: m.source_type,
            source_id: m.source_id,
            order_index: m.order_index,
            scores: vec![],
        }
    }
}

impl From<::entity::grade_scores::Model> for GradeScoreResponse {
    fn from(m: ::entity::grade_scores::Model) -> Self {
        let effective_score = m.override_score.or(m.score);
        Self {
            id: m.id.to_string(),
            grade_item_id: m.grade_item_id.to_string(),
            student_id: m.student_id.to_string(),
            score: m.score,
            is_auto_populated: m.is_auto_populated,
            override_score: m.override_score,
            effective_score,
        }
    }
}

impl From<::entity::term_grades::Model> for TermGradeResponse {
    fn from(m: ::entity::term_grades::Model) -> Self {
        let descriptor = m.transmuted_grade.map(|t| get_descriptor(t).to_string());
        Self {
            id: m.id.to_string(),
            class_id: m.class_id.to_string(),
            student_id: m.student_id.to_string(),
            term_number: m.term_number,
            initial_grade: m.initial_grade,
            transmuted_grade: m.transmuted_grade,
            descriptor,
            is_locked: m.is_locked,
        }
    }
}

// ===== BATCH RESPONSE SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct AllGradeDataResponse {
    pub grade_items: Vec<GradeItemResponse>,
    pub grade_summary: GradeSummaryResponse,
    pub term_number: i32,
    pub scores_by_item: HashMap<String, Vec<GradeScoreResponse>>,
    pub config: Option<GradingConfigResponse>,
}
