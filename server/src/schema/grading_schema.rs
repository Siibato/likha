use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::services::grade_computation::deped_weights::get_descriptor;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct SetupGradingConfigRequest {
    pub grade_level: String,
    pub subject_group: String,
    pub school_year: String,
    pub semester: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateGradingConfigRequest {
    pub grading_period_number: i32,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
}

#[derive(Debug, Deserialize)]
pub struct CreateGradeItemRequest {
    pub title: String,
    pub component: String,
    pub grading_period_number: Option<i32>,
    pub total_points: f64,
}

#[derive(Debug, Deserialize)]
pub struct UpdateGradeItemRequest {
    pub title: Option<String>,
    pub component: Option<String>,
    pub total_points: Option<f64>,
    pub order_index: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct StudentScore {
    pub student_id: Uuid,
    pub score: f64,
}

#[derive(Debug, Deserialize)]
pub struct BulkUpdateScoresRequest {
    pub scores: Vec<StudentScore>,
}

#[derive(Debug, Deserialize)]
pub struct OverrideScoreRequest {
    pub override_score: f64,
}

#[derive(Debug, Deserialize)]
pub struct QuarterQuery {
    pub grading_period_number: Option<i32>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct GradingConfigResponse {
    pub id: String,
    pub class_id: String,
    pub grading_period_number: Option<i32>,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
}

#[derive(Debug, Serialize)]
pub struct GradeItemResponse {
    pub id: String,
    pub class_id: String,
    pub title: String,
    pub component: String,
    pub grading_period_number: Option<i32>,
    pub total_points: f64,
    pub source_type: String,
    pub source_id: Option<String>,
    pub order_index: i32,
}

#[derive(Debug, Serialize)]
pub struct GradeScoreResponse {
    pub id: String,
    pub grade_item_id: String,
    pub student_id: String,
    pub score: Option<f64>,
    pub is_auto_populated: bool,
    pub override_score: Option<f64>,
    pub effective_score: Option<f64>,
}

#[derive(Debug, Serialize)]
pub struct PeriodGradeResponse {
    pub id: String,
    pub class_id: String,
    pub student_id: String,
    pub grading_period_number: i32,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub descriptor: Option<String>,
    pub is_locked: bool,
}

/// Backward-compat alias
pub type QuarterlyGradeResponse = PeriodGradeResponse;

#[derive(Debug, Serialize)]
pub struct FinalGradeResponse {
    pub student_id: String,
    pub period_grades: Vec<PeriodGradeResponse>,
    pub final_grade: Option<f64>,
}

#[derive(Debug, Serialize)]
pub struct GradeSummaryRow {
    pub student_id: String,
    pub student_name: String,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub descriptor: Option<String>,
    pub is_locked: bool,
}

#[derive(Debug, Serialize)]
pub struct GradeSummaryResponse {
    pub class_id: String,
    pub grading_period_number: i32,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
    pub students: Vec<GradeSummaryRow>,
}

#[derive(Debug, Serialize)]
pub struct PresetInfo {
    pub key: String,
    pub label: String,
    pub ww: f64,
    pub pt: f64,
    pub qa: f64,
}

#[derive(Debug, Serialize)]
pub struct DepEdPresetsResponse {
    pub presets: Vec<PresetInfo>,
}

#[derive(Debug, Serialize)]
pub struct ClassGradingSetupResponse {
    pub class_id: String,
    pub grade_level: String,
    pub school_year: String,
    pub grading_period_type: String,
    pub configs: Vec<GradingConfigResponse>,
}

// ===== GENERAL AVERAGE (GSA) SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct GeneralAverageResponse {
    pub class_id: String,
    pub students: Vec<StudentGeneralAverage>,
}

#[derive(Debug, Serialize)]
pub struct StudentGeneralAverage {
    pub student_id: String,
    pub student_name: String,
    pub general_average: Option<i32>,
    pub subject_count: usize,
    pub subjects: Vec<SubjectGrade>,
}

#[derive(Debug, Serialize)]
pub struct SubjectGrade {
    pub class_id: String,
    pub class_title: String,
    pub final_grade: Option<i32>,
}

// ===== SF9/SF10 SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct Sf9Response {
    pub student_id: String,
    pub student_name: String,
    pub grade_level: Option<String>,
    pub school_year: Option<String>,
    pub section: Option<String>,
    pub subjects: Vec<Sf9SubjectRow>,
    pub general_average: Option<Sf9QuarterlyAverages>,
}

#[derive(Debug, Serialize)]
pub struct Sf9SubjectRow {
    pub class_title: String,
    pub subject_group: Option<String>,
    pub q1: Option<i32>,
    pub q2: Option<i32>,
    pub q3: Option<i32>,
    pub q4: Option<i32>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct Sf9QuarterlyAverages {
    pub q1: Option<i32>,
    pub q2: Option<i32>,
    pub q3: Option<i32>,
    pub q4: Option<i32>,
    pub final_average: Option<i32>,
    pub descriptor: Option<String>,
}

// ===== FROM CONVERSIONS =====

impl From<::entity::grade_record::Model> for GradingConfigResponse {
    fn from(m: ::entity::grade_record::Model) -> Self {
        Self {
            id: m.id.to_string(),
            class_id: m.class_id.to_string(),
            grading_period_number: m.grading_period_number,
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
            grading_period_number: m.grading_period_number,
            total_points: m.total_points,
            source_type: m.source_type,
            source_id: m.source_id,
            order_index: m.order_index,
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

impl From<::entity::period_grades::Model> for PeriodGradeResponse {
    fn from(m: ::entity::period_grades::Model) -> Self {
        let descriptor = m.transmuted_grade.map(|t| get_descriptor(t).to_string());
        Self {
            id: m.id.to_string(),
            class_id: m.class_id.to_string(),
            student_id: m.student_id.to_string(),
            grading_period_number: m.grading_period_number,
            initial_grade: m.initial_grade,
            transmuted_grade: m.transmuted_grade,
            descriptor,
            is_locked: m.is_locked,
        }
    }
}
