use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // ── 1. previous_school_subjects: table swap (drop q1–q4, add term_type + deleted_at) ──

        // Clean up stale tables from previous failed runs
        db.execute_unprepared(r#"DROP TABLE IF EXISTS previous_school_subjects_backup"#).await.ok();
        db.execute_unprepared(r#"DROP TABLE IF EXISTS previous_school_term_grades"#).await.ok();
        db.execute_unprepared(r#"DROP TABLE IF EXISTS attendance_records_backup"#).await.ok();
        db.execute_unprepared(r#"DROP TABLE IF EXISTS previous_school_attendance_backup"#).await.ok();

        // Create backup of old table (has q1–q4 columns)
        db.execute_unprepared(
            r#"CREATE TABLE previous_school_subjects_backup AS SELECT * FROM previous_school_subjects"#,
        )
        .await?;

        // Drop old indexes and table
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_previous_school_subjects_student_id"#).await.ok();
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_previous_school_subjects_school_history_id"#).await.ok();
        db.execute_unprepared(r#"DROP TABLE previous_school_subjects"#).await?;

        // Recreate with new schema (same name)
        db.execute_unprepared(r#"
            CREATE TABLE previous_school_subjects (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                school_history_id TEXT NOT NULL,
                subject_name TEXT NOT NULL,
                subject_group TEXT,
                term_type TEXT NOT NULL DEFAULT 'quarterly',
                final_grade INTEGER,
                descriptor TEXT,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP
            )
        "#)
        .await?;

        // Copy data from backup
        db.execute_unprepared(r#"
            INSERT INTO previous_school_subjects (id, student_id, school_history_id, subject_name, subject_group, term_type, final_grade, descriptor, created_at, updated_at, deleted_at)
            SELECT id, student_id, school_history_id, subject_name, subject_group, 'quarterly', final_grade, descriptor, created_at, updated_at, NULL
            FROM previous_school_subjects_backup
        "#)
        .await?;

        // Create previous_school_term_grades and migrate q1–q4 from backup
        db.execute_unprepared(r#"
            CREATE TABLE previous_school_term_grades (
                id TEXT PRIMARY KEY,
                subject_id TEXT NOT NULL,
                term_number INTEGER NOT NULL,
                grade INTEGER,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(subject_id, term_number)
            )
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))), id, 1, q1_grade, created_at, updated_at, NULL
            FROM previous_school_subjects_backup WHERE q1_grade IS NOT NULL
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))), id, 2, q2_grade, created_at, updated_at, NULL
            FROM previous_school_subjects_backup WHERE q2_grade IS NOT NULL
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))), id, 3, q3_grade, created_at, updated_at, NULL
            FROM previous_school_subjects_backup WHERE q3_grade IS NOT NULL
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))), id, 4, q4_grade, created_at, updated_at, NULL
            FROM previous_school_subjects_backup WHERE q4_grade IS NOT NULL
        "#)
        .await?;

        // Create indexes
        db.execute_unprepared(
            r#"CREATE INDEX idx_previous_school_subjects_school_history_id ON previous_school_subjects(school_history_id)"#,
        )
        .await?;

        db.execute_unprepared(
            r#"CREATE INDEX idx_previous_school_term_grades_subject_id ON previous_school_term_grades(subject_id)"#,
        )
        .await?;

        // ── 2. attendance_records: table swap (drop days_absent, add deleted_at) ──

        db.execute_unprepared(
            r#"CREATE TABLE attendance_records_backup AS SELECT * FROM attendance_records"#,
        )
        .await?;

        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_attendance_records_student_id"#).await.ok();
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_attendance_records_class_id"#).await.ok();
        db.execute_unprepared(r#"DROP TABLE attendance_records"#).await?;

        db.execute_unprepared(r#"
            CREATE TABLE attendance_records (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                class_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                month TEXT NOT NULL,
                school_days INTEGER NOT NULL,
                days_present INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP
            )
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO attendance_records (id, student_id, class_id, school_year, month, school_days, days_present, created_at, updated_at, deleted_at)
            SELECT id, student_id, class_id, school_year, month, school_days, days_present, created_at, updated_at, NULL
            FROM attendance_records_backup
        "#)
        .await?;

        db.execute_unprepared(
            r#"CREATE UNIQUE INDEX idx_attendance_records_unique ON attendance_records(student_id, class_id, school_year, month)"#,
        )
        .await?;

        // ── 3. previous_school_attendance: table swap (drop days_absent, add deleted_at) ──

        db.execute_unprepared(
            r#"CREATE TABLE previous_school_attendance_backup AS SELECT * FROM previous_school_attendance"#,
        )
        .await?;

        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_previous_school_attendance_student_id"#).await.ok();
        db.execute_unprepared(r#"DROP INDEX IF EXISTS idx_previous_school_attendance_school_history_id"#).await.ok();
        db.execute_unprepared(r#"DROP TABLE previous_school_attendance"#).await?;

        db.execute_unprepared(r#"
            CREATE TABLE previous_school_attendance (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                school_history_id TEXT NOT NULL,
                school_year TEXT NOT NULL,
                month TEXT NOT NULL,
                school_days INTEGER NOT NULL,
                days_present INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP
            )
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_attendance (id, student_id, school_history_id, school_year, month, school_days, days_present, created_at, updated_at, deleted_at)
            SELECT id, student_id, school_history_id, school_year, month, school_days, days_present, created_at, updated_at, NULL
            FROM previous_school_attendance_backup
        "#)
        .await?;

        db.execute_unprepared(
            r#"CREATE UNIQUE INDEX idx_previous_school_attendance_unique ON previous_school_attendance(student_id, school_history_id, school_year, month)"#,
        )
        .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Restore previous_school_attendance from backup
        db.execute_unprepared(r#"DROP TABLE previous_school_attendance"#)
            .await?;
        db.execute_unprepared(
            r#"ALTER TABLE previous_school_attendance_backup RENAME TO previous_school_attendance"#,
        )
        .await?;

        // Restore attendance_records from backup
        db.execute_unprepared(r#"DROP TABLE attendance_records"#)
            .await?;
        db.execute_unprepared(
            r#"ALTER TABLE attendance_records_backup RENAME TO attendance_records"#,
        )
        .await?;

        // Drop previous_school_term_grades
        db.execute_unprepared(r#"DROP TABLE IF EXISTS previous_school_term_grades"#)
            .await?;

        // Restore previous_school_subjects from backup
        db.execute_unprepared(r#"DROP TABLE previous_school_subjects"#)
            .await?;
        db.execute_unprepared(
            r#"ALTER TABLE previous_school_subjects_backup RENAME TO previous_school_subjects"#,
        )
            .await?;

        Ok(())
    }
}
