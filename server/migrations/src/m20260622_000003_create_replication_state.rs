use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(ReplicationState::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ReplicationState::Id)
                            .string_len(36)
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(ReplicationState::PeerNodeId)
                            .string_len(100)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ReplicationState::LastSyncAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(ReplicationState::LastSyncSequence)
                            .big_integer()
                            .not_null()
                            .default(0),
                    )
                    .col(
                        ColumnDef::new(ReplicationState::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(ReplicationState::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_replication_state_peer")
                    .table(ReplicationState::Table)
                    .col(ReplicationState::PeerNodeId)
                    .unique()
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(ReplicationState::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum ReplicationState {
    Table,
    Id,
    PeerNodeId,
    LastSyncAt,
    LastSyncSequence,
    CreatedAt,
    UpdatedAt,
}
