use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // learner_details: drop admitted_to_grade, add father_contact, mother_contact
        db.execute_unprepared(r#"ALTER TABLE learner_details DROP COLUMN admitted_to_grade"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE learner_details ADD COLUMN father_contact TEXT"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE learner_details ADD COLUMN mother_contact TEXT"#)
            .await?;

        // school_settings → school_details
        db.execute_unprepared(r#"ALTER TABLE school_settings RENAME TO school_details"#)
            .await?;

        // core_values_records: add deleted_at
        db.execute_unprepared(r#"ALTER TABLE core_values_records ADD COLUMN deleted_at TIMESTAMP"#)
            .await?;

        // student_school_history: add deleted_at
        db.execute_unprepared(r#"ALTER TABLE student_school_history ADD COLUMN deleted_at TIMESTAMP"#)
            .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Reverse: student_school_history
        db.execute_unprepared(r#"ALTER TABLE student_school_history DROP COLUMN deleted_at"#)
            .await?;

        // Reverse: core_values_records
        db.execute_unprepared(r#"ALTER TABLE core_values_records DROP COLUMN deleted_at"#)
            .await?;

        // Reverse: school_details → school_settings
        db.execute_unprepared(r#"ALTER TABLE school_details RENAME TO school_settings"#)
            .await?;

        // Reverse: learner_details
        db.execute_unprepared(r#"ALTER TABLE learner_details DROP COLUMN mother_contact"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE learner_details DROP COLUMN father_contact"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE learner_details ADD COLUMN admitted_to_grade TEXT"#)
            .await?;

        Ok(())
    }
}
