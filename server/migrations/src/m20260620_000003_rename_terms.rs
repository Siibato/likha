use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // ── 1. Rename columns on 7 tables ──

        db.execute_unprepared(
            "ALTER TABLE classes RENAME COLUMN grading_period_type TO term_type;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE assignments RENAME COLUMN grading_period_number TO term_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE assessments RENAME COLUMN grading_period_number TO term_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE grade_items RENAME COLUMN grading_period_number TO term_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE grade_record RENAME COLUMN grading_period_number TO term_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE core_values_records RENAME COLUMN grading_period_number TO term_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE table_of_specifications RENAME COLUMN grading_period_number TO term_number;",
        )
        .await?;

        // ── 2. Migrate term_type values: 'quarter' → 'term' ──

        db.execute_unprepared(
            "UPDATE classes SET term_type = 'term' WHERE term_type = 'quarter';",
        )
        .await?;

        // ── 3. period_grades → term_grades table swap ──

        // Create the new table
        db.execute_unprepared(
            r#"
            CREATE TABLE term_grades (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                term_number INTEGER NOT NULL,
                initial_grade REAL,
                transmuted_grade INTEGER,
                is_locked BOOLEAN NOT NULL DEFAULT FALSE,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE(class_id, student_id, term_number)
            );
            "#,
        )
        .await?;

        // Migrate data from period_grades (drop computed_at, rename grading_period_number)
        db.execute_unprepared(
            r#"
            INSERT INTO term_grades (id, class_id, student_id, term_number, initial_grade, transmuted_grade, is_locked, created_at, updated_at, deleted_at)
            SELECT id, class_id, student_id, grading_period_number, initial_grade, transmuted_grade, is_locked, created_at, updated_at, deleted_at
            FROM period_grades;
            "#,
        )
        .await?;

        // Keep a backup for 7 days
        db.execute_unprepared(
            "CREATE TABLE term_grades_backup AS SELECT * FROM term_grades;",
        )
        .await?;

        // Drop the old table
        db.execute_unprepared("DROP TABLE period_grades;")
            .await?;

        // Create indexes on the new table
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_term_grades_class_id ON term_grades(class_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_term_grades_student_id ON term_grades(student_id);",
        )
        .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Reverse column renames
        db.execute_unprepared(
            "ALTER TABLE classes RENAME COLUMN term_type TO grading_period_type;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE assignments RENAME COLUMN term_number TO grading_period_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE assessments RENAME COLUMN term_number TO grading_period_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE grade_items RENAME COLUMN term_number TO grading_period_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE grade_record RENAME COLUMN term_number TO grading_period_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE core_values_records RENAME COLUMN term_number TO grading_period_number;",
        )
        .await?;

        db.execute_unprepared(
            "ALTER TABLE table_of_specifications RENAME COLUMN term_number TO grading_period_number;",
        )
        .await?;

        // Reverse term_type values
        db.execute_unprepared(
            "UPDATE classes SET grading_period_type = 'quarter' WHERE grading_period_type = 'term';",
        )
        .await?;

        // Recreate period_grades from term_grades_backup if it exists
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS period_grades (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                grading_period_number INTEGER NOT NULL,
                initial_grade REAL,
                transmuted_grade INTEGER,
                is_locked BOOLEAN NOT NULL DEFAULT FALSE,
                computed_at TIMESTAMP,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE(class_id, student_id, grading_period_number)
            );
            "#,
        )
        .await?;

        // Restore from backup if available
        db.execute_unprepared(
            r#"
            INSERT INTO period_grades (id, class_id, student_id, grading_period_number, initial_grade, transmuted_grade, is_locked, computed_at, created_at, updated_at, deleted_at)
            SELECT id, class_id, student_id, term_number, initial_grade, transmuted_grade, is_locked, NULL, created_at, updated_at, deleted_at
            FROM term_grades_backup;
            "#,
        )
        .await?;

        // Drop term_grades and backup
        db.execute_unprepared("DROP TABLE IF EXISTS term_grades;")
            .await?;
        db.execute_unprepared("DROP TABLE IF EXISTS term_grades_backup;")
            .await?;

        Ok(())
    }
}
