use uuid::Uuid;

pub enum CacheKey {
    // Class
    ClassListStudent(Uuid),
    ClassListTeacher(Uuid),
    ClassDetail(Uuid),
    ClassParticipants(Uuid),
    ClassMetadata(Uuid, String),

    // Assignment
    AssignmentListStudent(Uuid),
    AssignmentListTeacher(Uuid),
    AssignmentDetailStudent(Uuid),
    AssignmentDetailTeacher(Uuid),
    AssignmentListByClass(Uuid, Uuid, String),

    // Assessment
    AssessmentList(Uuid, Uuid),
    AssessmentDetail(Uuid, String),
    AssessmentSubmissions(Uuid),
    AssessmentStudentSubmission(Uuid, Uuid),
    AssessmentSubmissionDetail(Uuid),
    StudentResults(Uuid),
    StudentAssessmentSubmissions(Uuid, Uuid),

    // Grading
    GradeItems(Uuid, i32),
    PeriodGrades(Uuid, i32),
    StudentPeriodGrade(Uuid, Uuid, i32),
    StudentAllGrades(Uuid, Uuid),
    GradeSummary(Uuid, i32),
    ItemScores(Uuid),
    FinalGrade(Uuid, Uuid),
    GeneralAverages(Uuid),
    SF9(Uuid, Uuid),

    // Auth
    UserProfile(Uuid),

    // TOS
    TosList(Uuid),
    TosDetail(Uuid),

    // Learning Material
    MaterialList(Uuid),
    MaterialDetail(Uuid),

    // Setup
    SchoolInfo,
    SchoolSettings,
    SchoolCode,

    // Static
    DepedPresets,
}

impl CacheKey {
    pub fn as_str(&self) -> String {
        match self {
            // Class
            CacheKey::ClassListStudent(id) => format!("class:list:student:{}", id),
            CacheKey::ClassListTeacher(id) => format!("class:list:teacher:{}", id),
            CacheKey::ClassDetail(id) => format!("class:detail:{}", id),
            CacheKey::ClassParticipants(id) => format!("class:participants:{}", id),
            CacheKey::ClassMetadata(id, role) => format!("metadata:classes:{}:{}", id, role),

            // Assignment
            CacheKey::AssignmentListStudent(id) => format!("assignment:list:student:{}", id),
            CacheKey::AssignmentListTeacher(id) => format!("assignment:list:teacher:{}", id),
            CacheKey::AssignmentDetailStudent(id) => format!("assignment:detail:{}:student", id),
            CacheKey::AssignmentDetailTeacher(id) => format!("assignment:detail:{}:teacher", id),
            CacheKey::AssignmentListByClass(class_id, user_id, role) => format!("assignment:list:class:{}:{}:{}", class_id, user_id, role),

            // Assessment
            CacheKey::AssessmentList(user_id, class_id) => format!("assessment:list:{}:{}", user_id, class_id),
            CacheKey::AssessmentDetail(id, role) => format!("assessment:detail:{}:{}", id, role),
            CacheKey::AssessmentSubmissions(id) => format!("assessment:submissions:{}", id),
            CacheKey::AssessmentStudentSubmission(assessment_id, student_id) => format!("assessment:student_submission:{}:{}", assessment_id, student_id),
            CacheKey::AssessmentSubmissionDetail(id) => format!("assessment:submission:{}", id),
            CacheKey::StudentResults(id) => format!("assessment:results:{}", id),
            CacheKey::StudentAssessmentSubmissions(class_id, student_id) => format!("assessment:student_submissions:{}:{}", class_id, student_id),

            // Grading
            CacheKey::GradeItems(class_id, period) => format!("grade:items:{}:{}", class_id, period),
            CacheKey::PeriodGrades(class_id, period) => format!("grade:period:{}:{}", class_id, period),
            CacheKey::StudentPeriodGrade(class_id, student_id, period) => format!("grade:student:{}:{}:{}", class_id, student_id, period),
            CacheKey::StudentAllGrades(class_id, student_id) => format!("grade:student_all:{}:{}", class_id, student_id),
            CacheKey::GradeSummary(class_id, period) => format!("grade:summary:{}:{}", class_id, period),
            CacheKey::ItemScores(item_id) => format!("grade:item_scores:{}", item_id),
            CacheKey::FinalGrade(class_id, student_id) => format!("grade:final:{}:{}", class_id, student_id),
            CacheKey::GeneralAverages(class_id) => format!("grade:general_averages:{}", class_id),
            CacheKey::SF9(class_id, student_id) => format!("grade:sf9:{}:{}", class_id, student_id),

            // Auth
            CacheKey::UserProfile(id) => format!("user:profile:{}", id),

            // TOS
            CacheKey::TosList(class_id) => format!("tos:list:{}", class_id),
            CacheKey::TosDetail(id) => format!("tos:detail:{}", id),

            // Learning Material
            CacheKey::MaterialList(class_id) => format!("material:list:{}", class_id),
            CacheKey::MaterialDetail(id) => format!("material:detail:{}", id),

            // Setup
            CacheKey::SchoolInfo => "setup:school_info".to_string(),
            CacheKey::SchoolSettings => "setup:school_settings".to_string(),
            CacheKey::SchoolCode => "setup:school_code".to_string(),

            // Static
            CacheKey::DepedPresets => "config:deped_presets".to_string(),
        }
    }
}
