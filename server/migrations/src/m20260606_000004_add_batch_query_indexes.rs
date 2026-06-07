use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_question_choices_question_id ON question_choices(question_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_material_files_material_id ON material_files(material_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assessment_questions_assessment_id ON assessment_questions(assessment_id);",
        )
        .await
        .map(|_| ())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_question_choices_question_id;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_material_files_material_id;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_assessment_questions_assessment_id;",
        )
        .await
        .map(|_| ())
    }
}
