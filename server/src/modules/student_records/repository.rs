use sea_orm::DatabaseConnection;
use uuid::Uuid;
use chrono::NaiveDate;

use ::entity::{
    attendance_records, core_values_records, learner_details,
    previous_school_attendance, previous_school_subjects, student_school_history,
};
use crate::modules::student_records::repository_operations as ops;
use crate::utils::AppResult;

#[derive(Clone)]
pub struct StudentRecordsRepository {
    db: DatabaseConnection,
}

impl StudentRecordsRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ── Learner Details ──
    pub async fn get_learner_details(&self, user_id: Uuid) -> AppResult<Option<learner_details::Model>> {
        ops::get_learner_details(&self.db, user_id).await
    }

    pub async fn upsert_learner_details(
        &self,
        user_id: Uuid,
        lrn: Option<String>,
        age: Option<i32>,
        sex: Option<String>,
        track_strand: Option<String>,
        curriculum: Option<String>,
        birthdate: Option<NaiveDate>,
        birthplace: Option<String>,
        home_address: Option<String>,
        father_name: Option<String>,
        mother_name: Option<String>,
        guardian_name: Option<String>,
        guardian_contact: Option<String>,
        date_admitted: Option<NaiveDate>,
        admitted_to_grade: Option<String>,
    ) -> AppResult<learner_details::Model> {
        ops::upsert_learner_details(
            &self.db, user_id, lrn, age, sex, track_strand, curriculum,
            birthdate, birthplace, home_address, father_name, mother_name,
            guardian_name, guardian_contact, date_admitted, admitted_to_grade,
        ).await
    }

    // ── Attendance ──
    pub async fn get_attendance(
        &self,
        student_id: Uuid,
        class_id: Option<Uuid>,
        school_year: Option<&str>,
    ) -> AppResult<Vec<attendance_records::Model>> {
        ops::get_attendance(&self.db, student_id, class_id, school_year).await
    }

    pub async fn upsert_attendance(
        &self,
        student_id: Uuid,
        class_id: Uuid,
        school_year: String,
        month: String,
        school_days: i32,
        days_present: i32,
        days_absent: i32,
    ) -> AppResult<attendance_records::Model> {
        ops::upsert_attendance(
            &self.db, student_id, class_id, school_year, month,
            school_days, days_present, days_absent,
        ).await
    }

    // ── Core Values ──
    pub async fn get_core_values(
        &self,
        student_id: Uuid,
        class_id: Option<Uuid>,
        school_year: Option<&str>,
    ) -> AppResult<Vec<core_values_records::Model>> {
        ops::get_core_values(&self.db, student_id, class_id, school_year).await
    }

    pub async fn upsert_core_values(
        &self,
        student_id: Uuid,
        class_id: Uuid,
        school_year: String,
        grading_period_number: i32,
        core_value: String,
        behavior_statement: String,
        marking: String,
    ) -> AppResult<core_values_records::Model> {
        ops::upsert_core_values(
            &self.db, student_id, class_id, school_year, grading_period_number,
            core_value, behavior_statement, marking,
        ).await
    }

    // ── School History ──
    pub async fn get_school_history(&self, student_id: Uuid) -> AppResult<Vec<student_school_history::Model>> {
        ops::get_school_history(&self.db, student_id).await
    }

    pub async fn create_school_history(
        &self,
        student_id: Uuid,
        school_name: String,
        school_id: Option<String>,
        grade_level: String,
        school_year: String,
        section: Option<String>,
        date_from: Option<NaiveDate>,
        date_to: Option<NaiveDate>,
        record_type: String,
    ) -> AppResult<student_school_history::Model> {
        ops::create_school_history(
            &self.db, student_id, school_name, school_id, grade_level,
            school_year, section, date_from, date_to, record_type,
        ).await
    }

    pub async fn update_school_history(
        &self,
        id: Uuid,
        school_name: Option<String>,
        school_id: Option<Option<String>>,
        grade_level: Option<String>,
        school_year: Option<String>,
        section: Option<Option<String>>,
        date_from: Option<Option<NaiveDate>>,
        date_to: Option<Option<NaiveDate>>,
        record_type: Option<String>,
    ) -> AppResult<student_school_history::Model> {
        ops::update_school_history(
            &self.db, id, school_name, school_id, grade_level, school_year,
            section, date_from, date_to, record_type,
        ).await
    }

    pub async fn delete_school_history(&self, id: Uuid) -> AppResult<()> {
        ops::delete_school_history(&self.db, id).await
    }

    // ── Previous Subjects ──
    pub async fn get_previous_subjects(
        &self,
        student_id: Uuid,
        school_history_id: Option<Uuid>,
    ) -> AppResult<Vec<previous_school_subjects::Model>> {
        ops::get_previous_subjects(&self.db, student_id, school_history_id).await
    }

    pub async fn upsert_previous_subject(
        &self,
        student_id: Uuid,
        school_history_id: Uuid,
        subject_name: String,
        subject_group: Option<String>,
        q1_grade: Option<i32>,
        q2_grade: Option<i32>,
        q3_grade: Option<i32>,
        q4_grade: Option<i32>,
        final_grade: Option<i32>,
        descriptor: Option<String>,
    ) -> AppResult<previous_school_subjects::Model> {
        ops::upsert_previous_subject(
            &self.db, student_id, school_history_id, subject_name, subject_group,
            q1_grade, q2_grade, q3_grade, q4_grade, final_grade, descriptor,
        ).await
    }

    // ── Previous Attendance ──
    pub async fn get_previous_attendance(
        &self,
        student_id: Uuid,
        school_history_id: Option<Uuid>,
    ) -> AppResult<Vec<previous_school_attendance::Model>> {
        ops::get_previous_attendance(&self.db, student_id, school_history_id).await
    }

    pub async fn upsert_previous_attendance(
        &self,
        student_id: Uuid,
        school_history_id: Uuid,
        school_year: String,
        month: String,
        school_days: i32,
        days_present: i32,
        days_absent: i32,
    ) -> AppResult<previous_school_attendance::Model> {
        ops::upsert_previous_attendance(
            &self.db, student_id, school_history_id, school_year, month,
            school_days, days_present, days_absent,
        ).await
    }
}
