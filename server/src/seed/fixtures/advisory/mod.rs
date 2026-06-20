//! Advisory seeding fixtures: 1 teacher + 30 students, 4 classes,
//! full learner details, attendance, core values, school history.

pub mod users;
pub mod classes;
pub mod enrollments;
pub mod learner_details;
pub mod attendance;
pub mod core_values;
pub mod school_history;
pub mod previous_subjects;
pub mod previous_attendance;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn advisory_school_details(ctx: &SeedContext) -> SchoolDetailsSpec {
    SchoolDetailsSpec {
        id: 1,
        school_code: "LIKHA1".into(),
        school_name: Some("Likha National High School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        school_district: Some("District 1".into()),
        school_head_name: Some("Dr. Juan Dela Cruz".into()),
        school_head_position: Some("Principal II".into()),
        updated_at: ctx.now(),
    }
}

pub fn advisory_users(ctx: &SeedContext) -> Vec<UserSpec> {
    users::advisory_users(ctx)
}

pub fn advisory_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    classes::advisory_classes(ctx)
}

pub fn advisory_enrollments() -> Vec<EnrollmentSpec> {
    enrollments::advisory_enrollments()
}

pub fn advisory_learner_details() -> Vec<LearnerDetailsSpec> {
    learner_details::advisory_learner_details()
}

pub fn advisory_attendance() -> Vec<AttendanceSpec> {
    attendance::advisory_attendance()
}

pub fn advisory_core_values() -> Vec<CoreValuesSpec> {
    core_values::advisory_core_values()
}

pub fn advisory_school_history() -> Vec<SchoolHistorySpec> {
    school_history::advisory_school_history()
}

pub fn advisory_previous_subjects() -> Vec<PreviousSubjectSpec> {
    previous_subjects::advisory_previous_subjects()
}

pub fn advisory_previous_attendance() -> Vec<PreviousAttendanceSpec> {
    previous_attendance::advisory_previous_attendance()
}
