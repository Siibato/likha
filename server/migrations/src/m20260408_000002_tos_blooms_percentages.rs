use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN remembering_percentage REAL NOT NULL DEFAULT 16.67;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN understanding_percentage REAL NOT NULL DEFAULT 16.67;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN applying_percentage REAL NOT NULL DEFAULT 16.67;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN analyzing_percentage REAL NOT NULL DEFAULT 16.67;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN evaluating_percentage REAL NOT NULL DEFAULT 16.67;",
        )
        .await?;
        db.execute_unprepared(
            "ALTER TABLE table_of_specifications ADD COLUMN creating_percentage REAL NOT NULL DEFAULT 16.67;",
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
