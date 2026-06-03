use uuid::Uuid;

pub mod get_config;
pub mod get_all_configs;
pub mod upsert_config;
pub mod setup_defaults;
pub mod get_items;
pub mod get_items_by_component;
pub mod find_item;
pub mod find_by_source;
pub mod create_item;
pub mod update_item;
pub mod soft_delete_item;
pub mod get_scores_by_item;
pub mod get_scores_by_student_class_period;
pub mod upsert_score;
pub mod bulk_upsert_scores;
pub mod set_override;
pub mod clear_override;
pub mod get_period_grade;
pub mod get_all_for_class;
pub mod get_all_for_student;
pub mod upsert_period_grade;
pub mod get_enrolled_student_ids;
pub mod get_student_enrolled_classes;
pub mod get_period_grades_for_student_class;

#[derive(Debug)]
pub struct StudentEnrolledClass {
    pub class_id: Uuid,
    pub title: String,
    pub school_year: Option<String>,
}

pub use get_config::get_config;
pub use get_all_configs::get_all_configs;
pub use upsert_config::upsert_config;
pub use setup_defaults::setup_defaults;
pub use get_items::get_items;
pub use get_items_by_component::get_items_by_component;
pub use find_item::find_item;
pub use find_by_source::find_by_source;
pub use create_item::create_item;
pub use update_item::update_item;
pub use soft_delete_item::soft_delete_item;
pub use get_scores_by_item::get_scores_by_item;
pub use get_scores_by_student_class_period::get_scores_by_student_class_period;
pub use upsert_score::upsert_score;
pub use bulk_upsert_scores::bulk_upsert_scores;
pub use set_override::set_override;
pub use clear_override::clear_override;
pub use get_period_grade::get_period_grade;
pub use get_all_for_class::get_all_for_class;
pub use get_all_for_student::get_all_for_student;
pub use upsert_period_grade::upsert_period_grade;
pub use get_enrolled_student_ids::get_enrolled_student_ids;
pub use get_student_enrolled_classes::get_student_enrolled_classes;
pub use get_period_grades_for_student_class::get_period_grades_for_student_class;
