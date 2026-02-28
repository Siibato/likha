use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(ProcessedOperations::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ProcessedOperations::Id)
                            .string_len(36)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(ProcessedOperations::OperationId)
                            .string()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ProcessedOperations::UserId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ProcessedOperations::EntityType)
                            .string()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ProcessedOperations::Operation)
                            .string()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ProcessedOperations::Response)
                            .text()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ProcessedOperations::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_processed_ops_user_id")
                            .from(ProcessedOperations::Table, ProcessedOperations::UserId)
                            .to(Users::Table, Users::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        // Create unique index on operation_id
        manager
            .create_index(
                Index::create()
                    .unique()
                    .name("idx_processed_ops_operation_id")
                    .table(ProcessedOperations::Table)
                    .col(ProcessedOperations::OperationId)
                    .to_owned(),
            )
            .await?;

        // Create index on user_id
        manager
            .create_index(
                Index::create()
                    .name("idx_processed_ops_user_id")
                    .table(ProcessedOperations::Table)
                    .col(ProcessedOperations::UserId)
                    .to_owned(),
            )
            .await?;

        // Create index on created_at
        manager
            .create_index(
                Index::create()
                    .name("idx_processed_ops_created_at")
                    .table(ProcessedOperations::Table)
                    .col(ProcessedOperations::CreatedAt)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_index(
                Index::drop()
                    .name("idx_processed_ops_operation_id")
                    .table(ProcessedOperations::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_processed_ops_user_id")
                    .table(ProcessedOperations::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_processed_ops_created_at")
                    .table(ProcessedOperations::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_table(
                Table::drop()
                    .table(ProcessedOperations::Table)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum ProcessedOperations {
    Table,
    Id,
    OperationId,
    UserId,
    EntityType,
    Operation,
    Response,
    CreatedAt,
}

#[derive(DeriveIden)]
enum Users {
    Table,
    Id,
}
