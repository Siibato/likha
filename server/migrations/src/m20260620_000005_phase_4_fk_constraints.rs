use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite stores UUIDs as TEXT already; ALTER COLUMN TYPE and ADD CONSTRAINT
        // are PostgreSQL-only syntax. FK enforcement is handled at the application level.
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
