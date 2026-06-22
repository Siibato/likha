use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();
        let now = "2026-06-21 00:00:00";

        // Update existing rows 1-4 with the correct first-statement text
        db.execute_unprepared(&format!(
            r#"
            UPDATE core_values SET behavior_statement = CASE
                WHEN id = 1 THEN 'Expresses one''s spiritual beliefs while respecting those of others'
                WHEN id = 2 THEN 'Demonstrates and expresses pride in being a Filipino without looking down on others'
                WHEN id = 3 THEN 'Shows care and concern for the environment'
                WHEN id = 4 THEN 'Demonstrates pride in being a Filipino without looking down on others'
                ELSE behavior_statement
            END,
            core_value = CASE
                WHEN id = 2 THEN 'Makatao'
                WHEN id = 3 THEN 'Maka-Kalikasan'
                WHEN id = 4 THEN 'Maka-bansa'
                ELSE core_value
            END,
            updated_at = '{}'
            WHERE id IN (1, 2, 3, 4);
            "#,
            now
        ))
        .await?;

        // Insert rows 5-12 for the 2nd and 3rd statements of each core value
        db.execute_unprepared(&format!(
            r#"
            INSERT OR IGNORE INTO core_values (id, core_value, behavior_statement, created_at, updated_at) VALUES
            (5,  'Maka-Diyos',     'Shows adherence to ethical principles by upholding truth and justice at all times', '{}', '{}'),
            (6,  'Makatao',        'Listens attentively and responds appropriately to the opinions, ideas, and views of others', '{}', '{}'),
            (7,  'Maka-Kalikasan', 'Demonstrates resourcefulness and creativity in solving problems', '{}', '{}'),
            (8,  'Maka-bansa',     'Shows commitment to the ideals of democracy and nationalism', '{}', '{}'),
            (9,  'Maka-Diyos',     'Exhibits a deep sense of love for and service to the community and country', '{}', '{}'),
            (10, 'Makatao',        'Shows respect for and understanding of differences in culture, religion, and beliefs', '{}', '{}'),
            (11, 'Maka-Kalikasan', 'Exhibits a sense of responsibility for the sustainable use of resources', '{}', '{}'),
            (12, 'Maka-bansa',     'Exhibits a deep sense of patriotism and love for the country', '{}', '{}');
            "#,
            now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now
        ))
        .await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
