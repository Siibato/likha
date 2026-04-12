use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // === table_of_specifications: time unit + difficulty ratio defaults ===
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN time_unit TEXT NOT NULL DEFAULT 'days';",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN easy_percentage REAL NOT NULL DEFAULT 50.0;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN medium_percentage REAL NOT NULL DEFAULT 30.0;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN hard_percentage REAL NOT NULL DEFAULT 20.0;",
        )
        .await?;

        // === tos_competencies: per-competency count overrides (nullable) ===
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN easy_count INTEGER;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN medium_count INTEGER;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE tos_competencies ADD COLUMN hard_count INTEGER;",
        )
        .await?;

        // === assessments: linked TOS reference ===
        db.execute_unprepared(
            "ALTER TABLE assessments ADD COLUMN linked_tos_id TEXT;",
        )
        .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite doesn't support DROP COLUMN — columns will remain but be unused
        let _ = manager;
        Ok(())
    }
}
