use serde::{Deserialize, Serialize};

// ===== REQUEST SCHEMAS =====

#[derive(Debug, Deserialize)]
pub struct UpsertLearnerDetailsRequest {
    pub lrn: Option<String>,
    pub age: Option<i32>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub birthdate: Option<String>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub father_name: Option<String>,
    pub mother_name: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub date_admitted: Option<String>,
    pub admitted_to_grade: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpsertAttendanceRequest {
    pub class_id: String,
    pub school_year: String,
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
    pub days_absent: i32,
}

#[derive(Debug, Deserialize)]
pub struct UpsertCoreValuesRequest {
    pub class_id: String,
    pub school_year: String,
    pub grading_period_number: i32,
    pub core_value: String,
    pub behavior_statement: String,
    pub marking: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateSchoolHistoryRequest {
    pub school_name: String,
    pub school_id: Option<String>,
    pub grade_level: String,
    pub school_year: String,
    pub section: Option<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>,
    pub record_type: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateSchoolHistoryRequest {
    pub school_name: Option<String>,
    pub school_id: Option<Option<String>>,
    pub grade_level: Option<String>,
    pub school_year: Option<String>,
    pub section: Option<Option<String>>,
    pub date_from: Option<Option<String>>,
    pub date_to: Option<Option<String>>,
    pub record_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpsertPreviousSubjectRequest {
    pub school_history_id: String,
    pub subject_name: String,
    pub subject_group: Option<String>,
    pub q1_grade: Option<i32>,
    pub q2_grade: Option<i32>,
    pub q3_grade: Option<i32>,
    pub q4_grade: Option<i32>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpsertPreviousAttendanceRequest {
    pub school_history_id: String,
    pub school_year: String,
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
    pub days_absent: i32,
}

#[derive(Debug, Deserialize)]
pub struct AttendanceQuery {
    pub class_id: Option<String>,
    pub school_year: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CoreValuesQuery {
    pub class_id: Option<String>,
    pub school_year: Option<String>,
}

// ===== RESPONSE SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct LearnerDetailsResponse {
    pub id: String,
    pub user_id: String,
    pub lrn: Option<String>,
    pub age: Option<i32>,
    pub sex: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub birthdate: Option<String>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub father_name: Option<String>,
    pub mother_name: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub date_admitted: Option<String>,
    pub admitted_to_grade: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AttendanceResponse {
    pub id: String,
    pub student_id: String,
    pub class_id: String,
    pub school_year: String,
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
    pub days_absent: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CoreValuesResponse {
    pub id: String,
    pub student_id: String,
    pub class_id: String,
    pub school_year: String,
    pub grading_period_number: i32,
    pub core_value: String,
    pub behavior_statement: String,
    pub marking: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SchoolHistoryResponse {
    pub id: String,
    pub student_id: String,
    pub school_name: String,
    pub school_id: Option<String>,
    pub grade_level: String,
    pub school_year: String,
    pub section: Option<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>,
    pub record_type: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PreviousSubjectResponse {
    pub id: String,
    pub student_id: String,
    pub school_history_id: String,
    pub subject_name: String,
    pub subject_group: Option<String>,
    pub q1_grade: Option<i32>,
    pub q2_grade: Option<i32>,
    pub q3_grade: Option<i32>,
    pub q4_grade: Option<i32>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PreviousAttendanceResponse {
    pub id: String,
    pub student_id: String,
    pub school_history_id: String,
    pub school_year: String,
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
    pub days_absent: i32,
}

// ===== SF10 AGGREGATE SCHEMAS =====

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf10Response {
    pub student_id: String,
    pub student_name: String,
    pub lrn: Option<String>,
    pub birthdate: Option<String>,
    pub birthplace: Option<String>,
    pub home_address: Option<String>,
    pub sex: Option<String>,
    pub age: Option<i32>,
    pub father_name: Option<String>,
    pub mother_name: Option<String>,
    pub guardian_name: Option<String>,
    pub guardian_contact: Option<String>,
    pub track_strand: Option<String>,
    pub curriculum: Option<String>,
    pub current_school_year: Option<String>,
    pub current_grade_level: Option<String>,
    pub current_section: Option<String>,
    pub school_history: Vec<Sf10SchoolHistory>,
    pub scholastic_records: Vec<Sf10YearRecord>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf10SchoolHistory {
    pub id: String,
    pub school_name: String,
    pub school_id: Option<String>,
    pub grade_level: String,
    pub school_year: String,
    pub section: Option<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>,
    pub record_type: String,
    pub subjects: Vec<Sf10PreviousSubject>,
    pub attendance: Vec<Sf10AttendanceMonth>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf10YearRecord {
    pub school_year: String,
    pub grade_level: String,
    pub section: Option<String>,
    pub school_name: String,
    pub subjects: Vec<Sf10SubjectRow>,
    pub final_average: Option<i32>,
    pub descriptor: Option<String>,
    pub attendance: Vec<Sf10AttendanceMonth>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf10SubjectRow {
    pub class_title: String,
    pub subject_group: Option<String>,
    pub period_grades: Vec<Option<i32>>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf10PreviousSubject {
    pub subject_name: String,
    pub subject_group: Option<String>,
    pub q1_grade: Option<i32>,
    pub q2_grade: Option<i32>,
    pub q3_grade: Option<i32>,
    pub q4_grade: Option<i32>,
    pub final_grade: Option<i32>,
    pub descriptor: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Sf10AttendanceMonth {
    pub month: String,
    pub school_days: i32,
    pub days_present: i32,
    pub days_absent: i32,
}

// ===== FROM CONVERSIONS =====

impl From<::entity::learner_details::Model> for LearnerDetailsResponse {
    fn from(m: ::entity::learner_details::Model) -> Self {
        Self {
            id: m.id.to_string(),
            user_id: m.user_id.to_string(),
            lrn: m.lrn,
            age: m.age,
            sex: m.sex,
            track_strand: m.track_strand,
            curriculum: m.curriculum,
            birthdate: m.birthdate.map(|d| d.to_string()),
            birthplace: m.birthplace,
            home_address: m.home_address,
            father_name: m.father_name,
            mother_name: m.mother_name,
            guardian_name: m.guardian_name,
            guardian_contact: m.guardian_contact,
            date_admitted: m.date_admitted.map(|d| d.to_string()),
            admitted_to_grade: m.admitted_to_grade,
        }
    }
}

impl From<::entity::attendance_records::Model> for AttendanceResponse {
    fn from(m: ::entity::attendance_records::Model) -> Self {
        Self {
            id: m.id.to_string(),
            student_id: m.student_id.to_string(),
            class_id: m.class_id.to_string(),
            school_year: m.school_year,
            month: m.month,
            school_days: m.school_days,
            days_present: m.days_present,
            days_absent: m.days_absent,
        }
    }
}

impl From<::entity::core_values_records::Model> for CoreValuesResponse {
    fn from(m: ::entity::core_values_records::Model) -> Self {
        Self {
            id: m.id.to_string(),
            student_id: m.student_id.to_string(),
            class_id: m.class_id.to_string(),
            school_year: m.school_year,
            grading_period_number: m.grading_period_number,
            core_value: m.core_value,
            behavior_statement: m.behavior_statement,
            marking: m.marking,
        }
    }
}

impl From<::entity::student_school_history::Model> for SchoolHistoryResponse {
    fn from(m: ::entity::student_school_history::Model) -> Self {
        Self {
            id: m.id.to_string(),
            student_id: m.student_id.to_string(),
            school_name: m.school_name,
            school_id: m.school_id,
            grade_level: m.grade_level,
            school_year: m.school_year,
            section: m.section,
            date_from: m.date_from.map(|d| d.to_string()),
            date_to: m.date_to.map(|d| d.to_string()),
            record_type: m.record_type,
        }
    }
}

impl From<::entity::previous_school_subjects::Model> for PreviousSubjectResponse {
    fn from(m: ::entity::previous_school_subjects::Model) -> Self {
        Self {
            id: m.id.to_string(),
            student_id: m.student_id.to_string(),
            school_history_id: m.school_history_id.to_string(),
            subject_name: m.subject_name,
            subject_group: m.subject_group,
            q1_grade: m.q1_grade,
            q2_grade: m.q2_grade,
            q3_grade: m.q3_grade,
            q4_grade: m.q4_grade,
            final_grade: m.final_grade,
            descriptor: m.descriptor,
        }
    }
}

impl From<::entity::previous_school_attendance::Model> for PreviousAttendanceResponse {
    fn from(m: ::entity::previous_school_attendance::Model) -> Self {
        Self {
            id: m.id.to_string(),
            student_id: m.student_id.to_string(),
            school_history_id: m.school_history_id.to_string(),
            school_year: m.school_year,
            month: m.month,
            school_days: m.school_days,
            days_present: m.days_present,
            days_absent: m.days_absent,
        }
    }
}
