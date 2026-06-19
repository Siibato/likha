use uuid::Uuid;

pub mod get_learner_details;
pub mod upsert_learner_details;
pub mod get_attendance;
pub mod upsert_attendance;
pub mod get_core_values;
pub mod upsert_core_values;
pub mod get_school_history;
pub mod create_school_history;
pub mod update_school_history;
pub mod delete_school_history;
pub mod get_previous_subjects;
pub mod upsert_previous_subject;
pub mod get_previous_attendance;
pub mod upsert_previous_attendance;

pub use get_learner_details::get_learner_details;
pub use upsert_learner_details::upsert_learner_details;
pub use get_attendance::get_attendance;
pub use upsert_attendance::upsert_attendance;
pub use get_core_values::get_core_values;
pub use upsert_core_values::upsert_core_values;
pub use get_school_history::get_school_history;
pub use create_school_history::create_school_history;
pub use update_school_history::update_school_history;
pub use delete_school_history::delete_school_history;
pub use get_previous_subjects::get_previous_subjects;
pub use upsert_previous_subject::upsert_previous_subject;
pub use get_previous_attendance::get_previous_attendance;
pub use upsert_previous_attendance::upsert_previous_attendance;

pub struct StudentEnrolledClassInfo {
    pub class_id: Uuid,
    pub title: String,
    pub school_year: Option<String>,
}
