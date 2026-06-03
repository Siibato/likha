use chrono::NaiveDateTime;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct UserSpec {
    pub id: Uuid,
    pub username: String,
    pub full_name: String,
    pub role: String,
    pub password_hash: Option<String>,
    pub account_status: String,
    pub created_at: NaiveDateTime,
    pub activated_at: Option<NaiveDateTime>,
    pub deleted_at: Option<NaiveDateTime>,
}

#[derive(Debug, Clone)]
pub struct ClassSpec {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub grade_level: Option<String>,
    pub school_year: Option<String>,
    pub is_advisory: bool,
    pub is_archived: bool,
    pub created_at: NaiveDateTime,
    pub deleted_at: Option<NaiveDateTime>,
}

#[derive(Debug, Clone)]
pub struct EnrollmentSpec {
    pub class_id: Uuid,
    pub user_id: Uuid,
}

#[derive(Debug, Clone)]
pub struct TosSpec {
    pub id: Uuid,
    pub class_id: Uuid,
    pub period: i32,
    pub title: String,
    pub template_type: String,
    pub total_items: i32,
    pub time_limit_unit: String,
    pub ww_percent: f64,
    pub pt_percent: f64,
    pub qa_percent: f64,
    pub easy_percent: f64,
    pub average_percent: f64,
    pub difficult_percent: f64,
    pub remembering_percent: f64,
    pub understanding_percent: f64,
    pub applying_percent: f64,
    pub analyzing_percent: f64,
    pub evaluating_percent: f64,
    pub creating_percent: f64,
}

#[derive(Debug, Clone)]
pub struct CompetencySpec {
    pub id: Uuid,
    pub tos_id: Uuid,
    pub code: Option<String>,
    pub text: String,
    pub time_units_taught: i32,
    pub order: i32,
}

#[derive(Debug, Clone)]
pub struct AssessmentSpec {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub time_limit_minutes: i32,
    pub open_at: NaiveDateTime,
    pub close_at: NaiveDateTime,
    pub show_results_immediately: bool,
    pub total_points: i32,
    pub component: String,
    pub tos_id: Uuid,
    pub created_at: NaiveDateTime,
    pub deleted_at: Option<NaiveDateTime>,
    pub is_published: bool,
    pub results_released: bool,
    pub questions: Vec<QuestionSpec>,
}

#[derive(Debug, Clone)]
pub struct QuestionSpec {
    pub id: Uuid,
    pub question_type: String,
    pub text: String,
    pub points: i32,
    pub order: i32,
    pub is_multi_select: bool,
    pub tos_competency_id: Option<Uuid>,
    pub difficulty: Option<String>,
    pub cognitive_level: Option<String>,
    pub choices: Vec<ChoiceSpec>,
    pub answer_key: AnswerKeySpec,
}

#[derive(Debug, Clone)]
pub struct ChoiceSpec {
    pub text: String,
    pub is_correct: bool,
    pub order: i32,
}

#[derive(Debug, Clone)]
pub struct AnswerKeySpec {
    pub acceptable_answers: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct AssignmentSpec {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub instructions: String,
    pub total_points: i32,
    pub allows_text_submission: bool,
    pub allows_file_submission: bool,
    pub due_at: NaiveDateTime,
    pub component: String,
    pub created_at: NaiveDateTime,
    pub deleted_at: Option<NaiveDateTime>,
    pub is_published: bool,
    pub grading_period_number: i32,
}

#[derive(Debug, Clone)]
pub struct AssessmentSubmissionSpec {
    pub id: Uuid,
    pub assessment_id: Uuid,
    pub student_id: Uuid,
    pub started_at: NaiveDateTime,
    pub submitted_at: Option<NaiveDateTime>,
    pub total_points: f64,
    pub answers: Vec<SubmissionAnswerSpec>,
}

#[derive(Debug, Clone)]
pub struct SubmissionAnswerSpec {
    pub question_id: Uuid,
    pub choice_ids: Vec<Uuid>,
    pub text: Option<String>,
    pub is_correct: Option<bool>,
    pub points: f64,
}

#[derive(Debug, Clone)]
pub struct AssignmentSubmissionSpec {
    pub id: Uuid,
    pub assignment_id: Uuid,
    pub student_id: Uuid,
    pub text: Option<String>,
    pub status: String,
    pub points: Option<i32>,
    pub feedback: Option<String>,
    pub graded_by: Option<Uuid>,
    pub submitted_at: NaiveDateTime,
    pub graded_at: Option<NaiveDateTime>,
}

#[derive(Debug, Clone)]
pub struct MaterialSpec {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub content_text: Option<String>,
    pub order_index: i32,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Clone)]
pub struct SchoolSettingsSpec {
    pub id: i32,
    pub school_code: String,
    pub school_name: Option<String>,
    pub school_region: Option<String>,
    pub school_division: Option<String>,
    pub school_year: Option<String>,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone)]
pub struct GradeRecordSpec {
    pub class_id: Uuid,
    pub grading_period_type: String,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
}

#[derive(Debug, Clone)]
pub struct GradeScoreSpec {
    pub grade_item_id: Uuid,
    pub student_id: Uuid,
    pub score: Option<f64>,
    pub is_auto_populated: bool,
    pub override_score: Option<f64>,
}

#[derive(Debug, Clone)]
pub struct PeriodGradeSpec {
    pub class_id: Uuid,
    pub student_id: Uuid,
    pub grading_period_number: i32,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub is_locked: bool,
    pub computed_at: Option<NaiveDateTime>,
}
