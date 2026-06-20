use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // ── student_school_history ──
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS student_school_history (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                school_name TEXT NOT NULL,
                school_id TEXT,
                grade_level TEXT NOT NULL,
                school_year TEXT NOT NULL,
                section TEXT,
                date_from DATE,
                date_to DATE,
                record_type TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_student_school_history_student_id ON student_school_history(student_id);",
        )
        .await?;

        // ── previous_school_subjects ──
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS previous_school_subjects (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                school_history_id TEXT NOT NULL,
                subject_name TEXT NOT NULL,
                subject_group TEXT,
                q1_grade INTEGER,
                q2_grade INTEGER,
                q3_grade INTEGER,
                q4_grade INTEGER,
                final_grade INTEGER,
                descriptor TEXT,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (school_history_id) REFERENCES student_school_history(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_previous_school_subjects_student_id ON previous_school_subjects(student_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_previous_school_subjects_school_history_id ON previous_school_subjects(school_history_id);",
        )
        .await?;

        // ── previous_school_attendance ──
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS previous_school_attendance (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                school_history_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                month TEXT NOT NULL,
                school_days INTEGER NOT NULL,
                days_present INTEGER NOT NULL,
                days_absent INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (school_history_id) REFERENCES student_school_history(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_previous_school_attendance_student_id ON previous_school_attendance(student_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_previous_school_attendance_school_history_id ON previous_school_attendance(school_history_id);",
        )
        .await?;

        // ── attendance_records ──
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS attendance_records (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                class_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                month TEXT NOT NULL,
                school_days INTEGER NOT NULL,
                days_present INTEGER NOT NULL,
                days_absent INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_attendance_records_student_id ON attendance_records(student_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_attendance_records_class_id ON attendance_records(class_id);",
        )
        .await?;

        // ── core_values_records ──
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS core_values_records (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                class_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                grading_period_number INTEGER NOT NULL,
                core_value TEXT NOT NULL,
                behavior_statement TEXT NOT NULL,
                marking TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_core_values_records_student_id ON core_values_records(student_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_core_values_records_class_id ON core_values_records(class_id);",
        )
        .await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite down migrations for table drops are deferred to full reset
        Ok(())
    }
}
