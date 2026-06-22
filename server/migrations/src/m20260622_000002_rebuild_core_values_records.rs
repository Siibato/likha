use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Backup existing data
        db.execute_unprepared(r#"CREATE TABLE core_values_records_backup AS SELECT * FROM core_values_records"#)
            .await?;

        // Drop old indexes
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_core_values_records_student_id"#).await.ok();
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_core_values_records_class_id"#).await.ok();

        // Drop old table
        db.execute_unprepared(r#"DROP TABLE core_values_records"#).await?;

        // Recreate with schema matching the entity model
        db.execute_unprepared(r#"
            CREATE TABLE core_values_records (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                class_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                term_number INTEGER NOT NULL,
                core_value_id INTEGER NOT NULL,
                marking TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
        "#)
        .await?;

        // Migrate data from backup
        db.execute_unprepared(r#"
            INSERT INTO core_values_records (
                id, student_id, class_id, school_year, term_number,
                core_value_id, marking, created_at, updated_at, deleted_at
            )
            SELECT
                id, student_id, class_id, school_year, term_number,
                core_value_id, marking, created_at, updated_at, NULL
            FROM core_values_records_backup;
        "#)
        .await?;

        // Recreate indexes
        db.execute_unprepared(
            r#"CREATE INDEX idx_core_values_records_student_id ON core_values_records(student_id);"#,
        )
        .await?;

        db.execute_unprepared(
            r#"CREATE INDEX idx_core_values_records_class_id ON core_values_records(class_id);"#,
        )
        .await?;

        // Clean up backup
        db.execute_unprepared(r#"DROP TABLE core_values_records_backup"#).await.ok();

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Backup current data
        db.execute_unprepared(r#"CREATE TABLE core_values_records_backup AS SELECT * FROM core_values_records"#)
            .await?;

        // Drop indexes
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_core_values_records_student_id"#).await.ok();
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_core_values_records_class_id"#).await.ok();

        // Drop current table
        db.execute_unprepared(r#"DROP TABLE core_values_records"#).await?;

        // Recreate old schema (closest approximation before this migration)
        db.execute_unprepared(r#"
            CREATE TABLE core_values_records (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                class_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                term_number INTEGER NOT NULL,
                core_value TEXT NOT NULL,
                behavior_statement TEXT NOT NULL,
                marking TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
        "#)
        .await?;

        // Migrate data back (core_value and behavior_statement cannot be restored from backup)
        db.execute_unprepared(r#"
            INSERT INTO core_values_records (
                id, student_id, class_id, school_year, term_number,
                core_value, behavior_statement, marking, created_at, updated_at
            )
            SELECT
                id, student_id, class_id, school_year, term_number,
                '', '', marking, created_at, updated_at
            FROM core_values_records_backup;
        "#)
        .await?;

        db.execute_unprepared(
            r#"CREATE INDEX idx_core_values_records_student_id ON core_values_records(student_id);"#,
        )
        .await?;

        db.execute_unprepared(
            r#"CREATE INDEX idx_core_values_records_class_id ON core_values_records(class_id);"#,
        )
        .await?;

        db.execute_unprepared(r#"DROP TABLE core_values_records_backup"#).await.ok();

        Ok(())
    }
}
