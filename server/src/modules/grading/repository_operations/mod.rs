use uuid::Uuid;

pub mod bulk_upsert_scores;
pub mod clear_override;
pub mod create_item;
pub mod find_by_source;
pub mod find_item;
pub mod get_all_configs;
pub mod get_all_for_class;
pub mod get_all_for_student;
pub mod get_config;
pub mod get_enrolled_student_ids;
pub mod get_items;
pub mod get_items_by_component;
pub mod get_learner_details;
pub mod get_scores_by_item;
pub mod get_scores_by_student_class_term;
pub mod get_student_enrolled_classes;
pub mod get_term_grade;
pub mod get_term_grades_for_student_class;
pub mod set_override;
pub mod setup_defaults;
pub mod soft_delete_item;
pub mod update_item;
pub mod upsert_config;
pub mod upsert_score;
pub mod upsert_term_grade;

#[derive(Debug)]
pub struct StudentEnrolledClass {
    pub class_id: Uuid,
    pub title: String,
    pub school_year: Option<String>,
}

pub use bulk_upsert_scores::bulk_upsert_scores;
pub use clear_override::clear_override;
pub use create_item::create_item;
pub use find_by_source::find_by_source;
pub use find_item::find_item;
pub use get_all_configs::get_all_configs;
pub use get_all_for_class::get_all_for_class;
pub use get_all_for_student::get_all_for_student;
pub use get_config::get_config;
pub use get_enrolled_student_ids::get_enrolled_student_ids;
pub use get_items::get_items;
pub use get_items_by_component::get_items_by_component;
pub use get_learner_details::get_learner_details;
pub use get_scores_by_item::get_scores_by_item;
pub use get_scores_by_student_class_term::get_scores_by_student_class_term;
pub use get_student_enrolled_classes::get_student_enrolled_classes;
pub use get_term_grade::get_term_grade;
pub use get_term_grades_for_student_class::get_term_grades_for_student_class;
pub use set_override::set_override;
pub use setup_defaults::setup_defaults;
pub use soft_delete_item::soft_delete_item;
pub use update_item::update_item;
pub use upsert_config::upsert_config;
pub use upsert_score::upsert_score;
pub use upsert_term_grade::upsert_term_grade;
