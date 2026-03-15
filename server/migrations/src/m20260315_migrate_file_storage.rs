use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Add new columns to material_files one at a time
        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .add_column(ColumnDef::new(MaterialFiles::FilePath).string().null())
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .add_column(ColumnDef::new(MaterialFiles::FileHash).string().null())
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .add_column(ColumnDef::new(MaterialFiles::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        // Add hash index on material_files
        manager
            .create_index(
                Index::create()
                    .name("idx_material_files_hash")
                    .table(MaterialFiles::Table)
                    .col(MaterialFiles::FileHash)
                    .to_owned(),
            )
            .await?;

        // Add new columns to submission_files one at a time
        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .add_column(ColumnDef::new(SubmissionFiles::FilePath).string().null())
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .add_column(ColumnDef::new(SubmissionFiles::FileHash).string().null())
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .add_column(ColumnDef::new(SubmissionFiles::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        // Add hash index on submission_files
        manager
            .create_index(
                Index::create()
                    .name("idx_submission_files_hash")
                    .table(SubmissionFiles::Table)
                    .col(SubmissionFiles::FileHash)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Rollback: drop indices
        manager
            .drop_index(Index::drop().name("idx_submission_files_hash").to_owned())
            .await?;

        manager
            .drop_index(Index::drop().name("idx_material_files_hash").to_owned())
            .await?;

        // Rollback: remove new columns one at a time
        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .drop_column(SubmissionFiles::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .drop_column(SubmissionFiles::FileHash)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .drop_column(SubmissionFiles::FilePath)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .drop_column(MaterialFiles::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .drop_column(MaterialFiles::FileHash)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .drop_column(MaterialFiles::FilePath)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum MaterialFiles {
    Table,
    FilePath,
    FileHash,
    DeletedAt,
}

#[derive(DeriveIden)]
enum SubmissionFiles {
    Table,
    FilePath,
    FileHash,
    DeletedAt,
}
