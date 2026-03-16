use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .drop_column(MaterialFiles::FileData)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .drop_column(SubmissionFiles::FileData)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Restore columns — will be empty (NULL-unsafe) but schema-compatible
        manager
            .alter_table(
                Table::alter()
                    .table(SubmissionFiles::Table)
                    .add_column(ColumnDef::new(SubmissionFiles::FileData).binary().not_null())
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(MaterialFiles::Table)
                    .add_column(ColumnDef::new(MaterialFiles::FileData).binary().not_null())
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum MaterialFiles {
    Table,
    FileData,
}

#[derive(DeriveIden)]
enum SubmissionFiles {
    Table,
    FileData,
}
