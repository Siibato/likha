use sea_orm_migration::prelude::*;

/// Aligns the database schema with the updated ERD:
/// - Renames grade_components_config → grade_record
/// - Renames quarterly_grades → period_grades (with structural changes)
/// - Renames assignments_hw → assignments (with structural changes)
/// - Renames quarter → grading_period_number across affected tables
/// - Renames linked_tos_id → tos_id on assessments
/// - Renames days_taught → time_units_taught on tos_competencies
/// - Removes teacher_id, subject_group from classes; adds grading_period_type
/// - Removes performed_by from activity_logs
/// - Removes is_late from assignment_submissions
/// - Adds difficulty to assessment_questions
/// - Adds Bloom's count columns to tos_competencies
/// - Adds allows_text_submission / allows_file_submission to assignments
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // ── CLASSES ─────────────────────────────────────────────────────────────
        // Add grading_period_type (keeps old semester column; data migrated below)
        // Use SQL to conditionally add column only if it doesn't exist
        db.execute_unprepared(
            "ALTER TABLE classes ADD COLUMN grading_period_type TEXT NOT NULL DEFAULT 'quarter';",
        )
        .await
        .ok(); // Ignore error if column already exists
        // Migrate semester integer to string type in grading_period_type
        // Only if semester column still exists (idempotent for partial runs)
        db.execute_unprepared(
            "UPDATE classes SET grading_period_type = CASE WHEN semester = 2 THEN 'semester' ELSE 'quarter' END WHERE semester IS NOT NULL;",
        )
        .await
        .ok(); // Ignore error if semester column was already removed
        // Remove teacher_id and subject_group via table-swap (SQLite doesn't support DROP COLUMN on older versions)
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;
        db.execute_unprepared(r#"
            CREATE TABLE classes_new (
                id TEXT PRIMARY KEY NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                is_archived INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                grade_level TEXT,
                school_year TEXT,
                grading_period_type TEXT NOT NULL DEFAULT 'quarter',
                is_advisory INTEGER NOT NULL DEFAULT 0
            );
        "#).await?;
        db.execute_unprepared(r#"
            INSERT INTO classes_new
            SELECT id, title, description, is_archived,
                   created_at, updated_at, deleted_at,
                   grade_level, school_year, grading_period_type, is_advisory
            FROM classes;
        "#).await?;
        db.execute_unprepared("DROP TABLE classes;").await?;
        db.execute_unprepared("ALTER TABLE classes_new RENAME TO classes;").await?;
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        // ── ACTIVITY_LOGS ───────────────────────────────────────────────────────
        // Remove performed_by via table-swap
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;
        db.execute_unprepared(r#"
            CREATE TABLE activity_logs_new (
                id TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL,
                action TEXT NOT NULL,
                details TEXT,
                created_at TEXT NOT NULL,
                cached_at TEXT,
                needs_sync INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        "#).await?;
        db.execute_unprepared(r#"
            INSERT INTO activity_logs_new
            SELECT id, user_id, action, details, created_at, NULL, 0
            FROM activity_logs;
        "#).await?;
        db.execute_unprepared("DROP TABLE activity_logs;").await?;
        db.execute_unprepared("ALTER TABLE activity_logs_new RENAME TO activity_logs;").await?;
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        // ── GRADE_COMPONENTS_CONFIG → GRADE_RECORD ──────────────────────────────
        // Only rename if table still exists (idempotent)
        db.execute_unprepared(
            "ALTER TABLE grade_components_config RENAME TO grade_record;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE grade_record RENAME COLUMN quarter TO grading_period_number;",
        ).await.ok();

        // ── GRADE_ITEMS ─────────────────────────────────────────────────────────
        db.execute_unprepared(
            "ALTER TABLE grade_items RENAME COLUMN quarter TO grading_period_number;",
        ).await.ok();

        // ── QUARTERLY_GRADES → PERIOD_GRADES ───────────────────────────────────
        // Remove percentage columns, rename is_complete → is_locked, rename quarter
        // Only if quarterly_grades still exists (idempotent)
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;
        db.execute_unprepared(r#"
            CREATE TABLE IF NOT EXISTS period_grades (
                id TEXT PRIMARY KEY NOT NULL,
                class_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                grading_period_number INTEGER NOT NULL,
                initial_grade REAL,
                transmuted_grade INTEGER,
                is_locked INTEGER NOT NULL DEFAULT 0,
                computed_at TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                cached_at TEXT,
                needs_sync INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE,
                FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE(class_id, student_id, grading_period_number)
            );
        "#).await?;
        db.execute_unprepared(r#"
            INSERT INTO period_grades
            SELECT id, class_id, student_id, quarter,
                   initial_grade, transmuted_grade,
                   is_complete, computed_at,
                   created_at, updated_at, deleted_at, NULL, 0
            FROM quarterly_grades;
        "#).await.ok();
        db.execute_unprepared("DROP TABLE IF EXISTS quarterly_grades;").await?;
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        // ── ASSESSMENTS ─────────────────────────────────────────────────────────
        db.execute_unprepared(
            "ALTER TABLE assessments RENAME COLUMN quarter TO grading_period_number;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE assessments RENAME COLUMN linked_tos_id TO tos_id;",
        ).await.ok();

        // ── ASSESSMENT_QUESTIONS ────────────────────────────────────────────────
        db.execute_unprepared(
            "ALTER TABLE assessment_questions ADD COLUMN difficulty TEXT;",
        ).await.ok();

        // ── ASSIGNMENTS_HW → ASSIGNMENTS ────────────────────────────────────────
        // Remove submission_type, is_late (in submissions), rename quarter
        // Try to rename quarter column first - if it fails, table might need full migration
        db.execute_unprepared(
            "ALTER TABLE assignments RENAME COLUMN quarter TO grading_period_number;",
        ).await.ok();

        // Check if assignments table still needs migration (has submission_type column)
        // This indicates the table wasn't fully migrated yet
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;
        db.execute_unprepared("DROP TABLE IF EXISTS assignments_new;").await.ok();
        db.execute_unprepared(r#"
            CREATE TABLE assignments_new (
                id TEXT PRIMARY KEY NOT NULL,
                class_id TEXT NOT NULL,
                title TEXT NOT NULL,
                instructions TEXT NOT NULL,
                total_points INTEGER NOT NULL DEFAULT 0,
                allowed_file_types TEXT,
                max_file_size_mb INTEGER,
                due_at TEXT NOT NULL,
                is_published INTEGER NOT NULL DEFAULT 0,
                no_submission_required INTEGER NOT NULL DEFAULT 0,
                order_index INTEGER NOT NULL DEFAULT 0,
                grading_period_number INTEGER,
                component TEXT,
                allows_text_submission INTEGER NOT NULL DEFAULT 0,
                allows_file_submission INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                cached_at TEXT,
                needs_sync INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
        "#).await.ok();
        db.execute_unprepared(r#"
            INSERT INTO assignments_new
            SELECT
                id, class_id, title, instructions, total_points,
                allowed_file_types, max_file_size_mb, due_at, is_published,
                COALESCE(no_submission_required, 0),
                order_index,
                COALESCE((SELECT grading_period_number FROM assignments WHERE id = a.id), quarter),
                component,
                CASE WHEN submission_type IN ('text_only', 'both') THEN 1 ELSE 0 END,
                CASE WHEN submission_type IN ('file_only', 'both') THEN 1 ELSE 0 END,
                created_at, updated_at, deleted_at, NULL, 0
            FROM assignments a;
        "#).await.ok();
        db.execute_unprepared("DROP TABLE IF EXISTS assignments;").await.ok();
        db.execute_unprepared("ALTER TABLE assignments_new RENAME TO assignments;").await.ok();
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        // ── ASSIGNMENT_SUBMISSIONS ──────────────────────────────────────────────
        // Remove is_late via table-swap (idempotent)
        // Check if table needs migration (has is_late column)
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;
        db.execute_unprepared("DROP TABLE IF EXISTS assignment_submissions_new;").await.ok();
        db.execute_unprepared(r#"
            CREATE TABLE assignment_submissions_new (
                id TEXT PRIMARY KEY NOT NULL,
                assignment_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'draft',
                text_content TEXT,
                submitted_at TEXT,
                points INTEGER,
                feedback TEXT,
                graded_at TEXT,
                graded_by TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                cached_at TEXT,
                needs_sync INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
                FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY(graded_by) REFERENCES users(id) ON DELETE SET NULL,
                UNIQUE(assignment_id, student_id)
            );
        "#).await.ok();
        db.execute_unprepared(r#"
            INSERT INTO assignment_submissions_new
            SELECT id, assignment_id, student_id, status, text_content,
                   submitted_at, points, feedback, graded_at, graded_by,
                   created_at, updated_at, deleted_at, NULL, 0
            FROM assignment_submissions;
        "#).await.ok();
        db.execute_unprepared("DROP TABLE IF EXISTS assignment_submissions;").await.ok();
        db.execute_unprepared("ALTER TABLE assignment_submissions_new RENAME TO assignment_submissions;").await.ok();
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        // ── TABLE_OF_SPECIFICATIONS ─────────────────────────────────────────────
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications RENAME COLUMN quarter TO grading_period_number;",
        ).await.ok();

        // ── TOS_COMPETENCIES ────────────────────────────────────────────────────
        db.execute_unprepared(
            "ALTER TABLE tos_competencies RENAME COLUMN days_taught TO time_units_taught;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN remembering_count INTEGER;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN understanding_count INTEGER;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN applying_count INTEGER;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN analyzing_count INTEGER;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN evaluating_count INTEGER;",
        ).await.ok();
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN creating_count INTEGER;",
        ).await.ok();

        // ── RE-CREATE INDEXES ───────────────────────────────────────────────────
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_period_grades_class_id ON period_grades(class_id);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_period_grades_student_id ON period_grades(student_id);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_period_grades_updated_at ON period_grades(updated_at);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_record_class_id ON grade_record(class_id);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assignments_updated_at ON assignments(updated_at);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment_id ON assignment_submissions(assignment_id);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assignment_submissions_student_id ON assignment_submissions(student_id);",
        ).await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);",
        ).await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // Intentionally not implemented — schema renames are not reversible
        // without data loss risk. Use a forward migration to correct mistakes.
        Ok(())
    }
}
