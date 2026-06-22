use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();
        let now = "2026-06-22 00:00:00";

        // Update rows 1-8 to match the official SF9 card text exactly.
        db.execute_unprepared(&format!(
            r#"
            UPDATE core_values SET
                core_value = CASE id
                    WHEN 1 THEN 'Maka-Diyos'
                    WHEN 2 THEN 'Makatao'
                    WHEN 3 THEN 'Maka-kalikasan'
                    WHEN 4 THEN 'Makabansa'
                    WHEN 5 THEN 'Maka-Diyos'
                    WHEN 6 THEN 'Makatao'
                    WHEN 7 THEN 'Maka-kalikasan'
                    WHEN 8 THEN 'Makabansa'
                END,
                behavior_statement = CASE id
                    WHEN 1 THEN 'Expresses one''s spiritual beliefs while respecting the spiritual beliefs of others'
                    WHEN 2 THEN 'Demonstrates pride in being a Filipino; exercises the right and responsibilities of a Filipino citizen'
                    WHEN 3 THEN 'Cares for the environment and utilizes resources wisely, judiciously, and economically'
                    WHEN 4 THEN 'Demonstrates pride in being a Filipino; exercises the rights and responsibilities of a Filipino citizen'
                    WHEN 5 THEN 'Shows adherence to ethical principles by upholding truth'
                    WHEN 6 THEN 'Listens attentively and speaks to communicate effectively'
                    WHEN 7 THEN 'Demonstrates resourcefulness, creativity, and innovation in dealing with everyday problems'
                    WHEN 8 THEN 'Demonstrates appropriate behavior in carrying out activities in the school, community, and country'
                END,
                updated_at = '{}'
            WHERE id IN (1, 2, 3, 4, 5, 6, 7, 8);
            "#,
            now
        ))
        .await?;

        // Remove orphaned core_values_records that reference IDs 9-12
        // (the PDF already ignores these, so they are invisible on the card).
        db.execute_unprepared(
            "DELETE FROM core_values_records WHERE core_value_id IN (9, 10, 11, 12);",
        )
        .await?;

        // Delete the extra reference rows 9-12 from the core_values table.
        db.execute_unprepared(
            "DELETE FROM core_values WHERE id IN (9, 10, 11, 12);",
        )
        .await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
