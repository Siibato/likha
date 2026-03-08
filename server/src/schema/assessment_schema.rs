use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct CreateAssessmentRequest {
    pub title: String,
    pub description: Option<String>,
    pub time_limit_minutes: i32,
    pub open_at: String,
    pub close_at: String,
    pub show_results_immediately: Option<bool>,
    #[serde(default)]
    pub is_published: Option<bool>,
    // NEW: optional questions for atomic creation when publishing
    pub questions: Option<Vec<AddQuestionRequest>>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAssessmentRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub time_limit_minutes: Option<i32>,
    pub open_at: Option<String>,
    pub close_at: Option<String>,
    pub show_results_immediately: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct AddQuestionRequest {
    pub id: Option<Uuid>,
    pub question_type: String,
    pub question_text: String,
    pub points: i32,
    pub order_index: i32,
    pub is_multi_select: Option<bool>,
    pub choices: Option<Vec<ChoiceInput>>,
    pub correct_answers: Option<Vec<String>>,
    pub enumeration_items: Option<Vec<EnumerationItemInput>>,
}

#[derive(Debug, Deserialize)]
pub struct AddQuestionsRequest {
    pub questions: Vec<AddQuestionRequest>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateQuestionRequest {
    pub question_text: Option<String>,
    pub points: Option<i32>,
    pub order_index: Option<i32>,
    pub is_multi_select: Option<bool>,
    pub choices: Option<Vec<ChoiceInput>>,
    pub correct_answers: Option<Vec<String>>,
    pub enumeration_items: Option<Vec<EnumerationItemInput>>,
}

#[derive(Debug, Deserialize)]
pub struct ChoiceInput {
    pub choice_text: String,
    pub is_correct: bool,
    pub order_index: i32,
}

#[derive(Debug, Deserialize)]
pub struct EnumerationItemInput {
    pub order_index: i32,
    pub acceptable_answers: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct SaveAnswersRequest {
    pub answers: Vec<AnswerInput>,
}

#[derive(Debug, Deserialize)]
pub struct AnswerInput {
    pub question_id: Uuid,
    pub answer_text: Option<String>,
    pub selected_choice_ids: Option<Vec<Uuid>>,
    pub enumeration_answers: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct OverrideAnswerRequest {
    pub is_correct: bool,
}

#[derive(Debug, Deserialize)]
pub struct ReorderAssessmentRequest {
    pub new_order_index: i32,
}

#[derive(Debug, Deserialize)]
pub struct ReorderAssessmentsRequest {
    pub assessment_ids: Vec<Uuid>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct AssessmentResponse {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub time_limit_minutes: i32,
    pub open_at: String,
    pub close_at: String,
    pub show_results_immediately: bool,
    pub results_released: bool,
    pub is_published: bool,
    pub order_index: i32,
    pub total_points: i32,
    pub question_count: usize,
    pub submission_count: usize,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct AssessmentListResponse {
    pub assessments: Vec<AssessmentResponse>,
}

#[derive(Debug, Serialize)]
pub struct AssessmentDetailResponse {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub time_limit_minutes: i32,
    pub open_at: String,
    pub close_at: String,
    pub show_results_immediately: bool,
    pub results_released: bool,
    pub is_published: bool,
    pub order_index: i32,
    pub total_points: i32,
    pub questions: Vec<QuestionResponse>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct QuestionResponse {
    pub id: Uuid,
    pub question_type: String,
    pub question_text: String,
    pub points: i32,
    pub order_index: i32,
    pub is_multi_select: bool,
    pub choices: Option<Vec<ChoiceResponse>>,
    pub correct_answers: Option<Vec<CorrectAnswerResponse>>,
    pub enumeration_items: Option<Vec<EnumerationItemResponse>>,
}

#[derive(Debug, Serialize)]
pub struct ChoiceResponse {
    pub id: Uuid,
    pub choice_text: String,
    pub is_correct: bool,
    pub order_index: i32,
}

#[derive(Debug, Serialize)]
pub struct CorrectAnswerResponse {
    pub id: Uuid,
    pub answer_text: String,
}

#[derive(Debug, Serialize)]
pub struct EnumerationItemResponse {
    pub id: Uuid,
    pub order_index: i32,
    pub acceptable_answers: Vec<EnumerationItemAnswerResponse>,
}

#[derive(Debug, Serialize)]
pub struct EnumerationItemAnswerResponse {
    pub id: Uuid,
    pub answer_text: String,
}

#[derive(Debug, Serialize)]
pub struct SubmissionListResponse {
    pub submissions: Vec<SubmissionSummaryResponse>,
}

#[derive(Debug, Serialize)]
pub struct SubmissionSummaryResponse {
    pub id: Uuid,
    pub student_id: Uuid,
    pub student_name: String,
    pub student_username: String,
    pub started_at: String,
    pub submitted_at: Option<String>,
    pub auto_score: f64,
    pub final_score: f64,
    pub is_submitted: bool,
}

#[derive(Debug, Serialize)]
pub struct SubmissionDetailResponse {
    pub id: Uuid,
    pub assessment_id: Uuid,
    pub student_id: Uuid,
    pub student_name: String,
    pub started_at: String,
    pub submitted_at: Option<String>,
    pub auto_score: f64,
    pub final_score: f64,
    pub is_submitted: bool,
    pub answers: Vec<SubmissionAnswerResponse>,
}

#[derive(Debug, Serialize)]
pub struct SubmissionAnswerResponse {
    pub id: Uuid,
    pub question_id: Uuid,
    pub question_text: String,
    pub question_type: String,
    pub points: i32,
    pub answer_text: Option<String>,
    pub selected_choices: Option<Vec<SelectedChoiceResponse>>,
    pub enumeration_answers: Option<Vec<EnumerationAnswerResponse>>,
    pub is_auto_correct: Option<bool>,
    pub is_override_correct: Option<bool>,
    pub points_awarded: f64,
}

#[derive(Debug, Serialize)]
pub struct SelectedChoiceResponse {
    pub choice_id: Uuid,
    pub choice_text: String,
    pub is_correct: bool,
}

#[derive(Debug, Serialize)]
pub struct EnumerationAnswerResponse {
    pub id: Uuid,
    pub answer_text: String,
    pub matched_item_id: Option<Uuid>,
    pub is_auto_correct: Option<bool>,
    pub is_override_correct: Option<bool>,
}

#[derive(Debug, Serialize)]
pub struct StartSubmissionResponse {
    pub submission_id: Uuid,
    pub started_at: String,
    pub questions: Vec<StudentQuestionResponse>,
}

#[derive(Debug, Serialize)]
pub struct StudentQuestionResponse {
    pub id: Uuid,
    pub question_type: String,
    pub question_text: String,
    pub points: i32,
    pub order_index: i32,
    pub is_multi_select: bool,
    pub choices: Option<Vec<StudentChoiceResponse>>,
    pub enumeration_count: Option<usize>,
}

#[derive(Debug, Serialize)]
pub struct StudentChoiceResponse {
    pub id: Uuid,
    pub choice_text: String,
    pub order_index: i32,
}

#[derive(Debug, Serialize)]
pub struct StudentResultResponse {
    pub submission_id: Uuid,
    pub auto_score: f64,
    pub final_score: f64,
    pub total_points: i32,
    pub submitted_at: Option<String>,
    pub answers: Vec<StudentAnswerResultResponse>,
}

#[derive(Debug, Serialize)]
pub struct StudentAnswerResultResponse {
    pub question_id: Uuid,
    pub question_text: String,
    pub question_type: String,
    pub points: i32,
    pub points_awarded: f64,
    pub is_correct: Option<bool>,
    pub answer_text: Option<String>,
    pub selected_choices: Option<Vec<String>>,
    pub enumeration_answers: Option<Vec<StudentEnumAnswerResult>>,
    pub correct_answers: Option<Vec<String>>,
}

#[derive(Debug, Serialize)]
pub struct StudentEnumAnswerResult {
    pub answer_text: String,
    pub is_correct: Option<bool>,
}

#[derive(Debug, Serialize)]
pub struct AssessmentStatisticsResponse {
    pub assessment_id: Uuid,
    pub title: String,
    pub total_points: i32,
    pub submission_count: usize,
    pub class_statistics: ClassStatistics,
    pub question_statistics: Vec<QuestionStatistics>,
}

#[derive(Debug, Serialize)]
pub struct ClassStatistics {
    pub mean: f64,
    pub median: f64,
    pub highest: f64,
    pub lowest: f64,
    pub score_distribution: Vec<ScoreBucket>,
}

#[derive(Debug, Serialize)]
pub struct ScoreBucket {
    pub range: String,
    pub count: usize,
}

#[derive(Debug, Serialize)]
pub struct QuestionStatistics {
    pub question_id: Uuid,
    pub question_text: String,
    pub question_type: String,
    pub points: i32,
    pub correct_count: usize,
    pub incorrect_count: usize,
    pub correct_percentage: f64,
}

// ===== METADATA SCHEMAS =====

#[derive(Debug, Serialize)]
pub struct AssessmentMetadataResponse {
    pub last_modified: String,
    pub record_count: usize,
    pub etag: String,
}
