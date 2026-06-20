use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // assessments: change tos_id from TEXT to UUID and add FK
        db.execute_unprepared(
            r#"ALTER TABLE assessments ALTER COLUMN tos_id TYPE uuid USING tos_id::uuid"#,
        )
        .await?;
        db.execute_unprepared(
            r#"ALTER TABLE assessments ADD CONSTRAINT fk_assessments_tos_id
               FOREIGN KEY (tos_id) REFERENCES table_of_specifications(id) ON DELETE SET NULL"#,
        )
        .await?;

        // assessment_questions: change tos_competency_id from TEXT to UUID and add FK
        db.execute_unprepared(
            r#"ALTER TABLE assessment_questions ALTER COLUMN tos_competency_id TYPE uuid USING tos_competency_id::uuid"#,
        )
        .await?;
        db.execute_unprepared(
            r#"ALTER TABLE assessment_questions ADD CONSTRAINT fk_assessment_questions_tos_competency_id
               FOREIGN KEY (tos_competency_id) REFERENCES tos_competencies(id) ON DELETE SET NULL"#,
        )
        .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Reverse: assessment_questions
        db.execute_unprepared(
            r#"ALTER TABLE assessment_questions DROP CONSTRAINT IF EXISTS fk_assessment_questions_tos_competency_id"#,
        )
        .await?;
        db.execute_unprepared(
            r#"ALTER TABLE assessment_questions ALTER COLUMN tos_competency_id TYPE text USING tos_competency_id::text"#,
        )
        .await?;

        // Reverse: assessments
        db.execute_unprepared(
            r#"ALTER TABLE assessments DROP CONSTRAINT IF EXISTS fk_assessments_tos_id"#,
        )
        .await?;
        db.execute_unprepared(
            r#"ALTER TABLE assessments ALTER COLUMN tos_id TYPE text USING tos_id::text"#,
        )
        .await?;

        Ok(())
    }
}
