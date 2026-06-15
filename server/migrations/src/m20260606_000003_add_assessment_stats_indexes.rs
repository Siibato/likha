use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Composite index for the hot filter in assessment stats
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assessment_submissions_assessment_submitted ON assessment_submissions(assessment_id, submitted_at);",
        )
        .await?;

        // Index for deleted_at filtering
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_assessment_submissions_deleted_at ON assessment_submissions(deleted_at);",
        )
        .await?;

        // Essential for the LEFT JOIN in get_all_answer_details_for_assessment
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_submission_answer_items_submission_answer_id ON submission_answer_items(submission_answer_id);",
        )
        .await?;

        // Helps question-level aggregation
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_sub_answers_question_id ON submission_answers(question_id);",
        )
        .await?;

        // Recreate indexes lost during m20260316_000002_float_submission_score table swap
        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_submissions_assessment_id ON assessment_submissions(assessment_id);",
        )
        .await?;

        db.execute_unprepared(
            "CREATE INDEX IF NOT EXISTS idx_submissions_student_id ON assessment_submissions(user_id);",
        )
        .await
        .map(|_| ())?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_assessment_submissions_assessment_submitted;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_assessment_submissions_deleted_at;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_submission_answer_items_submission_answer_id;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_sub_answers_question_id;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_submissions_assessment_id;",
        )
        .await?;

        db.execute_unprepared(
            "DROP INDEX IF EXISTS idx_submissions_student_id;",
        )
        .await
        .map(|_| ())?;

        Ok(())
    }
}
