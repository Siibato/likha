use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS teacher_details (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL UNIQUE,
                license_id TEXT,
                rank TEXT,
                position TEXT,
                sex TEXT,
                birthdate DATE,
                home_address TEXT,
                date_hired DATE,
                education_level TEXT,
                specialization TEXT,
                contact_number TEXT,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_teacher_details_user_id ON teacher_details(user_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_teacher_details_deleted_at ON teacher_details(deleted_at);",
        )
        .await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite down migrations for table drops are deferred to full reset
        Ok(())
    }
}
