use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // === EXTEND EXISTING TABLES ===

        // classes: grading metadata
        db.execute_unprepared("ALTER TABLE classes ADD COLUMN grade_level TEXT;")
            .await?;
        db.execute_unprepared("ALTER TABLE classes ADD COLUMN subject_group TEXT;")
            .await?;
        db.execute_unprepared("ALTER TABLE classes ADD COLUMN school_year TEXT;")
            .await?;
        db.execute_unprepared("ALTER TABLE classes ADD COLUMN semester INTEGER;")
            .await?;

        // assessments: DepEd component classification
        db.execute_unprepared("ALTER TABLE assessments ADD COLUMN quarter INTEGER;")
            .await?;
        db.execute_unprepared(
            "ALTER TABLE assessments ADD COLUMN is_departmental_exam BOOLEAN DEFAULT FALSE;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE assessments ADD COLUMN component TEXT DEFAULT 'written_work';",
        )
        .await?;

        // assignments: DepEd component classification
        db.execute_unprepared("ALTER TABLE assignments ADD COLUMN quarter INTEGER;")
            .await?;
        db.execute_unprepared(
            "ALTER TABLE assignments ADD COLUMN no_submission_required BOOLEAN DEFAULT FALSE;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE assignments ADD COLUMN component TEXT DEFAULT 'performance_task';",
        )
        .await?;

        // === CREATE NEW TABLES ===

        // grade_components_config: per-class per-quarter weight configuration
        db.execute_unprepared(
            r#"
            CREATE TABLE grade_components_config (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                quarter INTEGER NOT NULL,
                ww_weight REAL NOT NULL DEFAULT 30.0,
                pt_weight REAL NOT NULL DEFAULT 50.0,
                qa_weight REAL NOT NULL DEFAULT 20.0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(class_id, quarter),
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        // grade_items: individual gradeable items
        db.execute_unprepared(
            r#"
            CREATE TABLE grade_items (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                title TEXT NOT NULL,
                component TEXT NOT NULL,
                quarter INTEGER NOT NULL,
                total_points REAL NOT NULL,
                is_departmental_exam BOOLEAN NOT NULL DEFAULT FALSE,
                source_type TEXT NOT NULL DEFAULT 'manual',
                source_id TEXT,
                order_index INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        // grade_scores: per-student per-grade-item scores
        db.execute_unprepared(
            r#"
            CREATE TABLE grade_scores (
                id TEXT PRIMARY KEY,
                grade_item_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                score REAL,
                is_auto_populated BOOLEAN NOT NULL DEFAULT FALSE,
                override_score REAL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(grade_item_id, student_id),
                FOREIGN KEY (grade_item_id) REFERENCES grade_items(id) ON DELETE CASCADE,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        // quarterly_grades: computed/cached quarterly grades
        db.execute_unprepared(
            r#"
            CREATE TABLE quarterly_grades (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                quarter INTEGER NOT NULL,
                ww_percentage REAL,
                pt_percentage REAL,
                qa_percentage REAL,
                ww_weighted REAL,
                pt_weighted REAL,
                qa_weighted REAL,
                initial_grade REAL,
                transmuted_grade INTEGER,
                is_complete BOOLEAN NOT NULL DEFAULT FALSE,
                computed_at TIMESTAMP,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(class_id, student_id, quarter),
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        // === INDEXES ===

        // grade_components_config
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_configs_class_id ON grade_components_config(class_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_configs_updated_at ON grade_components_config(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_configs_deleted_at ON grade_components_config(deleted_at);",
        )
        .await?;

        // grade_items
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_items_class_id ON grade_items(class_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_items_class_quarter ON grade_items(class_id, quarter);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_items_component ON grade_items(component);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_items_source ON grade_items(source_type, source_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_items_updated_at ON grade_items(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_items_deleted_at ON grade_items(deleted_at);",
        )
        .await?;

        // grade_scores
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_scores_item_id ON grade_scores(grade_item_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_scores_student_id ON grade_scores(student_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_scores_updated_at ON grade_scores(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_grade_scores_deleted_at ON grade_scores(deleted_at);",
        )
        .await?;

        // quarterly_grades
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_quarterly_grades_class_id ON quarterly_grades(class_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_quarterly_grades_student_id ON quarterly_grades(student_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_quarterly_grades_class_quarter ON quarterly_grades(class_id, quarter);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_quarterly_grades_updated_at ON quarterly_grades(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_quarterly_grades_deleted_at ON quarterly_grades(deleted_at);",
        )
        .await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite doesn't support DROP COLUMN, so down migration is a no-op
        // A full reset-db is needed to revert
        Ok(())
    }
}
