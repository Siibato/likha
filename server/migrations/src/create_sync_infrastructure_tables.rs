use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Create sync_cursors table for resumable pagination
        manager
            .create_table(
                Table::create()
                    .table(SyncCursors::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(SyncCursors::Id).string_len(36).not_null().primary_key())
                    .col(ColumnDef::new(SyncCursors::UserId).string_len(36).not_null())
                    .col(ColumnDef::new(SyncCursors::EntityType).string_len(100).not_null())
                    .col(ColumnDef::new(SyncCursors::Offset).integer().not_null().default(0))
                    .col(
                        ColumnDef::new(SyncCursors::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(ColumnDef::new(SyncCursors::ExpiresAt).timestamp().not_null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sync_cursors_user_id")
                    .table(SyncCursors::Table)
                    .col(SyncCursors::UserId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sync_cursors_expires_at")
                    .table(SyncCursors::Table)
                    .col(SyncCursors::ExpiresAt)
                    .to_owned(),
            )
            .await?;

        // Create sync_conflicts table for conflict tracking and resolution
        manager
            .create_table(
                Table::create()
                    .table(SyncConflicts::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(SyncConflicts::Id).string_len(36).not_null().primary_key())
                    .col(ColumnDef::new(SyncConflicts::UserId).string_len(36).not_null())
                    .col(ColumnDef::new(SyncConflicts::EntityType).string_len(100).not_null())
                    .col(ColumnDef::new(SyncConflicts::EntityId).string_len(36).not_null())
                    .col(ColumnDef::new(SyncConflicts::ClientData).text().null())
                    .col(ColumnDef::new(SyncConflicts::ServerData).text().null())
                    .col(ColumnDef::new(SyncConflicts::ClientUpdatedAt).timestamp().null())
                    .col(ColumnDef::new(SyncConflicts::ServerUpdatedAt).timestamp().null())
                    .col(ColumnDef::new(SyncConflicts::Resolution).string_len(100).null())
                    .col(ColumnDef::new(SyncConflicts::ResolvedAt).timestamp().null())
                    .col(
                        ColumnDef::new(SyncConflicts::CreatedAt)
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
                    .name("idx_sync_conflicts_user_id")
                    .table(SyncConflicts::Table)
                    .col(SyncConflicts::UserId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sync_conflicts_resolved_at")
                    .table(SyncConflicts::Table)
                    .col(SyncConflicts::ResolvedAt)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Drop indexes first
        manager
            .drop_index(
                Index::drop()
                    .name("idx_sync_cursors_user_id")
                    .table(SyncCursors::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_sync_cursors_expires_at")
                    .table(SyncCursors::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_sync_conflicts_user_id")
                    .table(SyncConflicts::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_sync_conflicts_resolved_at")
                    .table(SyncConflicts::Table)
                    .to_owned(),
            )
            .await?;

        // Drop tables
        manager
            .drop_table(Table::drop().table(SyncCursors::Table).to_owned())
            .await?;

        manager
            .drop_table(Table::drop().table(SyncConflicts::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum SyncCursors {
    Table,
    Id,
    UserId,
    EntityType,
    Offset,
    CreatedAt,
    ExpiresAt,
}

#[derive(DeriveIden)]
enum SyncConflicts {
    Table,
    Id,
    UserId,
    EntityType,
    EntityId,
    ClientData,
    ServerData,
    ClientUpdatedAt,
    ServerUpdatedAt,
    Resolution,
    ResolvedAt,
    CreatedAt,
}
