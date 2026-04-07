use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // === EXTEND EXISTING TABLES ===

        // classes: advisory flag
        db.execute_unprepared(
            "ALTER TABLE classes ADD COLUMN is_advisory BOOLEAN NOT NULL DEFAULT FALSE;",
        )
        .await?;

        // assessment_questions: TOS linkage
        db.execute_unprepared(
            "ALTER TABLE assessment_questions ADD COLUMN tos_competency_id TEXT;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE assessment_questions ADD COLUMN cognitive_level TEXT;",
        )
        .await?;

        // === CREATE NEW TABLES ===

        // table_of_specifications: per-class per-quarter test blueprint
        db.execute_unprepared(
            r#"
            CREATE TABLE table_of_specifications (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                quarter INTEGER NOT NULL,
                title TEXT NOT NULL,
                classification_mode TEXT NOT NULL,
                total_items INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id),
                UNIQUE(class_id, quarter)
            );
            "#,
        )
        .await?;

        // tos_competencies: competencies within a TOS
        db.execute_unprepared(
            r#"
            CREATE TABLE tos_competencies (
                id TEXT PRIMARY KEY,
                tos_id TEXT NOT NULL,
                competency_code TEXT,
                competency_text TEXT NOT NULL,
                days_taught INTEGER NOT NULL,
                order_index INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (tos_id) REFERENCES table_of_specifications(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        // melcs: bundled read-only DepEd MELCS reference data
        db.execute_unprepared(
            r#"
            CREATE TABLE melcs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                subject TEXT NOT NULL,
                grade_level TEXT NOT NULL,
                quarter INTEGER,
                competency_code TEXT NOT NULL,
                competency_text TEXT NOT NULL,
                domain TEXT
            );
            "#,
        )
        .await?;

        // === INDEXES ===

        db.execute_unprepared(
            "CREATE INDEX idx_tos_class_id ON table_of_specifications(class_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_tos_updated_at ON table_of_specifications(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_tos_comp_tos_id ON tos_competencies(tos_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_tos_comp_updated_at ON tos_competencies(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_melcs_subject_grade ON melcs(subject, grade_level);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_aq_tos_comp_id ON assessment_questions(tos_competency_id);",
        )
        .await?;

        // === SEED MELCS SAMPLE DATA (Math 7, Q1) ===

        db.execute_unprepared(
            r#"
            INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
            ('Mathematics', '7', 1, 'M7NS-Ia-1', 'describes well-defined sets, subsets, universal sets, and the null set and cardinality of sets', 'Numbers and Number Sense'),
            ('Mathematics', '7', 1, 'M7NS-Ia-2', 'illustrates the union and intersection of sets and the difference of two sets', 'Numbers and Number Sense'),
            ('Mathematics', '7', 1, 'M7NS-Ib-1', 'uses Venn Diagrams to represent sets, subsets, and set operations', 'Numbers and Number Sense'),
            ('Mathematics', '7', 1, 'M7NS-Ib-2', 'solves problems involving sets', 'Numbers and Number Sense'),
            ('Mathematics', '7', 1, 'M7NS-Ic-1', 'represents the absolute value of a number on a number line as the distance of a number from 0', 'Numbers and Number Sense'),
            ('Mathematics', '7', 1, 'M7NS-Ic-d-1', 'performs fundamental operations on integers', 'Numbers and Number Sense'),
            ('Mathematics', '7', 1, 'M7NS-Ie-1', 'illustrates the different properties of operations on the set of integers', 'Numbers and Number Sense'),
            ('Science', '7', 1, 'S7MT-Ia-1', 'describe the components of a scientific investigation', 'Scientific Inquiry'),
            ('Science', '7', 1, 'S7MT-Ib-2', 'distinguish between accurate and precise measurements', 'Scientific Inquiry'),
            ('English', '7', 1, 'EN7RC-Ia-1', 'use the appropriate reading style for different texts', 'Reading Comprehension');
            "#,
        )
        .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared("DROP TABLE IF EXISTS melcs;").await?;
        db.execute_unprepared("DROP TABLE IF EXISTS tos_competencies;").await?;
        db.execute_unprepared("DROP TABLE IF EXISTS table_of_specifications;").await?;

        // SQLite doesn't support DROP COLUMN, so we skip reverting column additions
        // The columns (is_advisory, tos_competency_id, cognitive_level) will remain
        // but be unused after rollback

        Ok(())
    }
}
