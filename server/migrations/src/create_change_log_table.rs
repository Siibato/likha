use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(ChangeLog::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ChangeLog::Sequence)
                            .big_integer()
                            .not_null()
                            .auto_increment()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(ChangeLog::Id)
                            .uuid()
                            .not_null()
                            .unique_key(),
                    )
                    .col(
                        ColumnDef::new(ChangeLog::EntityType)
                            .string_len(50)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ChangeLog::EntityId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ChangeLog::Operation)
                            .string_len(10)
                            .not_null(),
                    )
                    .col(ColumnDef::new(ChangeLog::PerformedBy).uuid().not_null())
                    .col(ColumnDef::new(ChangeLog::Payload).text().null())
                    .col(
                        ColumnDef::new(ChangeLog::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_change_log_performed_by")
                            .from(ChangeLog::Table, ChangeLog::PerformedBy)
                            .to(Users::Table, Users::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_change_log_sequence")
                    .table(ChangeLog::Table)
                    .col(ChangeLog::Sequence)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_change_log_entity")
                    .table(ChangeLog::Table)
                    .col(ChangeLog::EntityType)
                    .col(ChangeLog::EntityId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(ChangeLog::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum ChangeLog {
    Table,
    Sequence,
    Id,
    EntityType,
    EntityId,
    Operation,
    PerformedBy,
    Payload,
    CreatedAt,
}

#[derive(DeriveIden)]
enum Users {
    Table,
    Id,
}
