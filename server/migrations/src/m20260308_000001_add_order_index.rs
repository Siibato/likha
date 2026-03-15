use sea_orm_migration::prelude::*;

pub struct Migration;

impl MigrationName for Migration {
    fn name(&self) -> &str {
        "m20260308_000001_add_order_index"
    }
}

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Add order_index column to assignments
        manager
            .get_connection()
            .execute_unprepared("ALTER TABLE assignments ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0")
            .await?;

        // Create index on assignments (class_id, order_index)
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE INDEX IF NOT EXISTS idx_assignments_class_order ON assignments (class_id, order_index)",
            )
            .await?;

        // Seed order_index for existing assignments based on created_at order within each class
        manager
            .get_connection()
            .execute_unprepared(
                "UPDATE assignments
                SET order_index = (
                    SELECT COUNT(*) FROM assignments a2
                    WHERE a2.class_id = assignments.class_id
                        AND a2.created_at <= assignments.created_at
                        AND a2.deleted_at IS NULL
                ) - 1
                WHERE deleted_at IS NULL",
            )
            .await?;

        // Add order_index column to assessments
        manager
            .get_connection()
            .execute_unprepared("ALTER TABLE assessments ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0")
            .await?;

        // Create index on assessments (class_id, order_index)
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE INDEX IF NOT EXISTS idx_assessments_class_order ON assessments (class_id, order_index)",
            )
            .await?;

        // Seed order_index for existing assessments based on created_at order within each class
        manager
            .get_connection()
            .execute_unprepared(
                "UPDATE assessments
                SET order_index = (
                    SELECT COUNT(*) FROM assessments a2
                    WHERE a2.class_id = assessments.class_id
                        AND a2.created_at <= assessments.created_at
                        AND a2.deleted_at IS NULL
                ) - 1
                WHERE deleted_at IS NULL",
            )
            .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Drop indexes
        manager
            .get_connection()
            .execute_unprepared("DROP INDEX IF EXISTS idx_assignments_class_order")
            .await?;

        manager
            .get_connection()
            .execute_unprepared("DROP INDEX IF EXISTS idx_assessments_class_order")
            .await?;

        // Note: SQLite does not support DROP COLUMN, so we cannot remove the columns
        // This migration is one-way for SQLite databases

        Ok(())
    }
}
