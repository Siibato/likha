use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite doesn't support ALTER COLUMN, so we recreate the table
        let db = manager.get_connection();

        // Disable foreign key checks temporarily
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;

        // Create new table with REAL instead of INTEGER for total_points
        db.execute_unprepared(
            r#"
            CREATE TABLE assessment_submissions_new (
                id TEXT PRIMARY KEY,
                assessment_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                started_at TIMESTAMP NOT NULL,
                submitted_at TIMESTAMP,
                total_points REAL NOT NULL DEFAULT 0.0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY(assessment_id) REFERENCES assessments(id),
                FOREIGN KEY(user_id) REFERENCES users(id)
            );
            "#,
        )
        .await?;

        // Copy data from old table to new table
        db.execute_unprepared(
            r#"
            INSERT INTO assessment_submissions_new (id, assessment_id, user_id, started_at, submitted_at, total_points, created_at, updated_at, deleted_at)
            SELECT id, assessment_id, user_id, started_at, submitted_at, CAST(total_points AS REAL), created_at, updated_at, deleted_at
            FROM assessment_submissions;
            "#,
        )
        .await?;

        // Drop old table
        db.execute_unprepared("DROP TABLE assessment_submissions;")
            .await?;

        // Rename new table to original name
        db.execute_unprepared(
            "ALTER TABLE assessment_submissions_new RENAME TO assessment_submissions;",
        )
        .await?;

        // Re-enable foreign key checks
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Rollback: recreate with INTEGER column
        let db = manager.get_connection();

        // Disable foreign key checks temporarily
        db.execute_unprepared("PRAGMA foreign_keys = OFF;").await?;

        db.execute_unprepared(
            r#"
            CREATE TABLE assessment_submissions_new (
                id TEXT PRIMARY KEY,
                assessment_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                started_at TIMESTAMP NOT NULL,
                submitted_at TIMESTAMP,
                total_points INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY(assessment_id) REFERENCES assessments(id),
                FOREIGN KEY(user_id) REFERENCES users(id)
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            r#"
            INSERT INTO assessment_submissions_new (id, assessment_id, user_id, started_at, submitted_at, total_points, created_at, updated_at, deleted_at)
            SELECT id, assessment_id, user_id, started_at, submitted_at, CAST(total_points AS INTEGER), created_at, updated_at, deleted_at
            FROM assessment_submissions;
            "#,
        )
        .await?;

        db.execute_unprepared("DROP TABLE assessment_submissions;")
            .await?;

        db.execute_unprepared(
            "ALTER TABLE assessment_submissions_new RENAME TO assessment_submissions;",
        )
        .await?;

        // Re-enable foreign key checks
        db.execute_unprepared("PRAGMA foreign_keys = ON;").await?;

        Ok(())
    }
}
