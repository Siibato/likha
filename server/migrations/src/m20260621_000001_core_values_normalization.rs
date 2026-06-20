use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // ── Create core_values reference table ──
        db.execute_unprepared(
            r#"
            CREATE TABLE IF NOT EXISTS core_values (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                core_value TEXT NOT NULL,
                behavior_statement TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL
            );
            "#,
        )
        .await?;

        // Seed the 4 DepEd core values
        let now = "2026-06-21 00:00:00";
        db.execute_unprepared(&format!(
            r#"
            INSERT INTO core_values (id, core_value, behavior_statement, created_at, updated_at) VALUES
            (1, 'Maka-Diyos', 'Shows respect for all beliefs and faiths; participates in spiritual activities', '{}', '{}'),
            (2, 'Makatao', 'Demonstrates empathy and compassion toward peers and community members', '{}', '{}'),
            (3, 'Maka-Kalikasan', 'Shows care for the environment by participating in eco-friendly practices', '{}', '{}'),
            (4, 'Maka-bansa', 'Expresses pride in being Filipino and contributes to nation-building', '{}', '{}');
            "#,
            now, now, now, now, now, now, now, now
        ))
        .await?;

        // ── Add core_value_id column to core_values_records ──
        db.execute_unprepared(
            "ALTER TABLE core_values_records ADD COLUMN core_value_id INTEGER;",
        )
        .await?;

        // Migrate existing data: map core_value strings to ids
        db.execute_unprepared(
            r#"
            UPDATE core_values_records SET core_value_id = CASE
                WHEN core_value = 'Maka-Diyos' THEN 1
                WHEN core_value = 'Makatao' THEN 2
                WHEN core_value = 'Maka-Kalikasan' THEN 3
                WHEN core_value = 'Maka-bansa' THEN 4
                ELSE 0
            END;
            "#,
        )
        .await?;

        // SQLite cannot DROP COLUMN easily, so we leave the old columns.
        // The entity model will only reference core_value_id.
        // A full table rebuild would be needed for strict schema enforcement.

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // SQLite down migrations are deferred to full reset
        Ok(())
    }
}
