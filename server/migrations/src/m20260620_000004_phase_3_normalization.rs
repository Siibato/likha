use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // ── 1. previous_school_subjects: table swap (drop q1–q4, add term_type + deleted_at) ──

        // Create backup
        db.execute_unprepared(
            r#"CREATE TABLE previous_school_subjects_backup AS SELECT * FROM previous_school_subjects"#,
        )
        .await?;

        // Create new table
        db.execute_unprepared(r#"
            CREATE TABLE previous_school_subjects_new (
                id UUID PRIMARY KEY,
                student_id UUID NOT NULL,
                school_history_id UUID NOT NULL,
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

        // Migrate data
        db.execute_unprepared(r#"
            INSERT INTO previous_school_subjects_new (id, student_id, school_history_id, subject_name, subject_group, term_type, final_grade, descriptor, created_at, updated_at, deleted_at)
            SELECT id, student_id, school_history_id, subject_name, subject_group, 'quarterly', final_grade, descriptor, created_at, updated_at, NULL
            FROM previous_school_subjects
        "#)
        .await?;

        // Create previous_school_term_grades BEFORE dropping old table (so we can read q1–q4)
        db.execute_unprepared(r#"
            CREATE TABLE previous_school_term_grades (
                id UUID PRIMARY KEY,
                subject_id UUID NOT NULL REFERENCES previous_school_subjects_new(id) ON DELETE CASCADE,
                term_number INTEGER NOT NULL,
                grade INTEGER,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(subject_id, term_number)
            )
        "#)
        .await?;

        // Migrate q1–q4 data into previous_school_term_grades
        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT gen_random_uuid(), id, 1, q1_grade, created_at, updated_at, NULL
            FROM previous_school_subjects WHERE q1_grade IS NOT NULL
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT gen_random_uuid(), id, 2, q2_grade, created_at, updated_at, NULL
            FROM previous_school_subjects WHERE q2_grade IS NOT NULL
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT gen_random_uuid(), id, 3, q3_grade, created_at, updated_at, NULL
            FROM previous_school_subjects WHERE q3_grade IS NOT NULL
        "#)
        .await?;

        db.execute_unprepared(r#"
            INSERT INTO previous_school_term_grades (id, subject_id, term_number, grade, created_at, updated_at, deleted_at)
            SELECT gen_random_uuid(), id, 4, q4_grade, created_at, updated_at, NULL
            FROM previous_school_subjects WHERE q4_grade IS NOT NULL
        "#)
        .await?;

        // Drop old table, rename new
        db.execute_unprepared(r#"DROP TABLE previous_school_subjects"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE previous_school_subjects_new RENAME TO previous_school_subjects"#)
            .await?;

        // Create index
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

        db.execute_unprepared(r#"
            CREATE TABLE attendance_records_new (
                id UUID PRIMARY KEY,
                student_id UUID NOT NULL,
                class_id UUID NOT NULL,
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
            INSERT INTO attendance_records_new (id, student_id, class_id, school_year, month, school_days, days_present, created_at, updated_at, deleted_at)
            SELECT id, student_id, class_id, school_year, month, school_days, days_present, created_at, updated_at, NULL
            FROM attendance_records
        "#)
        .await?;

        db.execute_unprepared(r#"DROP TABLE attendance_records"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE attendance_records_new RENAME TO attendance_records"#)
            .await?;

        // Recreate indexes
        db.execute_unprepared(
            r#"CREATE UNIQUE INDEX idx_attendance_records_unique ON attendance_records(student_id, class_id, school_year, month)"#,
        )
        .await?;

        // ── 3. previous_school_attendance: table swap (drop days_absent, add deleted_at) ──

        db.execute_unprepared(
            r#"CREATE TABLE previous_school_attendance_backup AS SELECT * FROM previous_school_attendance"#,
        )
        .await?;

        db.execute_unprepared(r#"
            CREATE TABLE previous_school_attendance_new (
                id UUID PRIMARY KEY,
                student_id UUID NOT NULL,
                school_history_id UUID NOT NULL,
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
            INSERT INTO previous_school_attendance_new (id, student_id, school_history_id, school_year, month, school_days, days_present, created_at, updated_at, deleted_at)
            SELECT id, student_id, school_history_id, school_year, month, school_days, days_present, created_at, updated_at, NULL
            FROM previous_school_attendance
        "#)
        .await?;

        db.execute_unprepared(r#"DROP TABLE previous_school_attendance"#)
            .await?;
        db.execute_unprepared(r#"ALTER TABLE previous_school_attendance_new RENAME TO previous_school_attendance"#)
            .await?;

        // Recreate unique index
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
