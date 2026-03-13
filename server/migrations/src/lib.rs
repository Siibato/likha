pub use sea_orm_migration::prelude::*;

mod create_users_table;
mod create_refresh_tokens_table;
mod create_classes_table;
mod create_class_enrollments_table;
mod create_activity_logs_table;
mod create_assessment_tables;
mod create_assignment_tables;
mod create_learning_materials_tables;
mod add_last_modified_timestamps;
mod create_change_log_table;
mod create_database_metadata_table;
mod add_soft_delete_columns;
mod create_sync_infrastructure_tables;
mod create_login_attempts_table;
mod add_processed_operations;
mod add_updated_at_to_questions;
mod add_updated_at_to_assessment_submissions;
mod m20260305_000001_schema_v2;
mod m20260308_000001_add_order_index;
mod m20260313_000001_schema_v3;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(create_database_metadata_table::Migration),
            Box::new(create_users_table::Migration),
            Box::new(create_refresh_tokens_table::Migration),
            Box::new(create_classes_table::Migration),
            Box::new(create_class_enrollments_table::Migration),
            Box::new(create_activity_logs_table::Migration),
            Box::new(create_assessment_tables::Migration),
            Box::new(create_assignment_tables::Migration),
            Box::new(create_learning_materials_tables::Migration),
            Box::new(add_last_modified_timestamps::Migration),
            Box::new(create_change_log_table::Migration),
            Box::new(add_soft_delete_columns::Migration),
            Box::new(create_sync_infrastructure_tables::Migration),
            Box::new(create_login_attempts_table::Migration),
            Box::new(add_processed_operations::Migration),
            Box::new(add_updated_at_to_questions::Migration),
            Box::new(add_updated_at_to_assessment_submissions::Migration),
            Box::new(m20260305_000001_schema_v2::Migration),
            Box::new(m20260308_000001_add_order_index::Migration),
            Box::new(m20260313_000001_schema_v3::Migration),
        ]
    }
}
