use chrono::NaiveDateTime;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct UserSpec {
    pub id: Uuid,
    pub username: String,
    pub first_name: String,
    pub last_name: String,
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
    pub term_number: i32,
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
    pub term_number: i32,
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
    pub id: Uuid,
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
    pub term_number: i32,
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
pub struct SchoolDetailsSpec {
    pub id: i32,
    pub school_code: String,
    pub school_name: Option<String>,
    pub school_region: Option<String>,
    pub school_division: Option<String>,
    pub school_year: Option<String>,
    pub school_district: Option<String>,
    pub school_head_name: Option<String>,
    pub school_head_position: Option<String>,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Clone)]
pub struct GradeRecordSpec {
    pub class_id: Uuid,
    pub term_number: i32,
    pub ww_weight: f64,
    pub pt_weight: f64,
    pub qa_weight: f64,
}

#[derive(Debug, Clone)]
pub struct GradeItemSpec {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub component: String,
    pub term_number: i32,
    pub total_points: f64,
    pub source_type: String,
    pub source_id: Option<String>,
    pub order_index: i32,
}

#[derive(Debug, Clone)]
pub struct GradeScoreSpec {
    pub grade_item_id: Uuid,
    pub student_id: Uuid,
    pub score: Option<f64>,
    pub is_auto_populated: bool,
    pub override_score: Option<f64>,
    pub component: String,
    pub term_number: i32,
}

#[derive(Debug, Clone)]
pub struct TermGradeSpec {
    pub class_id: Uuid,
    pub student_id: Uuid,
    pub term_number: i32,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
    pub is_locked: bool,
}

#[derive(Debug, Clone)]
pub struct ActivityLogSpec {
    pub id: Uuid,
    pub user_id: Uuid,
    pub action: String,
    pub details: Option<String>,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Clone)]
pub struct LearnerDetailsSpec {
    pub id: Uuid,
    pub user_id: Uuid,
    pub lrn: Option<String>,
    pub age: Option<i32>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub birthdate: Option<chrono::NaiveDate>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub father_name: Option<String>,
    pub father_contact: Option<String>,
    pub mother_name: Option<String>,
    pub mother_contact: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub date_admitted: Option<chrono::NaiveDate>,
}

#[derive(Debug, Clone)]
pub struct AttendanceSpec {
    pub id: Uuid,
    pub student_id: Uuid,
    pub class_id: Uuid,
    pub school_year: String,
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
}

#[derive(Debug, Clone)]
pub struct CoreValuesSpec {
    pub id: Uuid,
    pub student_id: Uuid,
    pub class_id: Uuid,
    pub school_year: String,
    pub term_number: i32,
    pub core_value_id: i32,
    pub marking: String,
}

#[derive(Debug, Clone)]
pub struct SchoolHistorySpec {
    pub id: Uuid,
    pub student_id: Uuid,
    pub school_name: String,
    pub school_id: Option<String>,
    pub grade_level: String,
    pub school_year: String,
    pub section: Option<String>,
    pub date_from: Option<chrono::NaiveDate>,
    pub date_to: Option<chrono::NaiveDate>,
    pub record_type: String,
}

#[derive(Debug, Clone)]
pub struct PreviousSubjectSpec {
    pub id: Uuid,
    pub student_id: Uuid,
    pub school_history_id: Uuid,
    pub subject_name: String,
    pub subject_group: Option<String>,
    pub term_type: String,
    pub term_grades: Vec<Option<i32>>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Clone)]
pub struct PreviousAttendanceSpec {
    pub id: Uuid,
    pub student_id: Uuid,
    pub school_history_id: Uuid,
    pub school_year: String,
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
}
