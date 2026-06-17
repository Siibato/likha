use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // SQLite doesn't support ALTER TABLE DROP CONSTRAINT, so we recreate the table.
        // Disable foreign key enforcement during the swap since tos_competencies
        // references this table.
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;

        // Clean up from any previous failed run
        db.execute_unprepared("DROP TABLE IF EXISTS table_of_specifications_new;")
            .await?;

        db.execute_unprepared(
            r#"
            CREATE TABLE table_of_specifications_new (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                grading_period_number INTEGER NOT NULL,
                title TEXT NOT NULL,
                classification_mode TEXT NOT NULL,
                total_items INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                time_unit TEXT NOT NULL DEFAULT 'days',
                easy_percentage REAL NOT NULL DEFAULT 50.0,
                medium_percentage REAL NOT NULL DEFAULT 30.0,
                hard_percentage REAL NOT NULL DEFAULT 20.0,
                remembering_percentage REAL NOT NULL DEFAULT 16.67,
                understanding_percentage REAL NOT NULL DEFAULT 16.67,
                applying_percentage REAL NOT NULL DEFAULT 16.67,
                analyzing_percentage REAL NOT NULL DEFAULT 16.67,
                evaluating_percentage REAL NOT NULL DEFAULT 16.67,
                creating_percentage REAL NOT NULL DEFAULT 16.67,
                FOREIGN KEY (class_id) REFERENCES classes(id)
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "INSERT INTO table_of_specifications_new SELECT * FROM table_of_specifications;",
        )
        .await?;

        db.execute_unprepared("DROP TABLE table_of_specifications;").await?;

        db.execute_unprepared(
            "ALTER TABLE table_of_specifications_new RENAME TO table_of_specifications;",
        )
        .await?;

        // Recreate indexes that were lost when the table was dropped
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_tos_class_id ON table_of_specifications(class_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_tos_updated_at ON table_of_specifications(updated_at);",
        )
        .await?;

        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // Re-adding the UNIQUE constraint would require another table recreation.
        Ok(())
    }
}
