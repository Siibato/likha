use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(ActivityLogs::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ActivityLogs::Id)
                            .uuid()
                            .not_null()
                            .primary_key(),
                    )
                    .col(ColumnDef::new(ActivityLogs::UserId).uuid().not_null())
                    .col(
                        ColumnDef::new(ActivityLogs::Action)
                            .string_len(50)
                            .not_null(),
                    )
                    .col(ColumnDef::new(ActivityLogs::PerformedBy).uuid().null())
                    .col(ColumnDef::new(ActivityLogs::Details).text().null())
                    .col(
                        ColumnDef::new(ActivityLogs::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_activity_logs_user")
                            .from(ActivityLogs::Table, ActivityLogs::UserId)
                            .to(Users::Table, Users::Id),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_activity_logs_performed_by")
                            .from(ActivityLogs::Table, ActivityLogs::PerformedBy)
                            .to(Users::Table, Users::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_activity_logs_user_id")
                    .table(ActivityLogs::Table)
                    .col(ActivityLogs::UserId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_activity_logs_action")
                    .table(ActivityLogs::Table)
                    .col(ActivityLogs::Action)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(ActivityLogs::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum ActivityLogs {
    Table,
    Id,
    UserId,
    Action,
    PerformedBy,
    Details,
    CreatedAt,
}

#[derive(DeriveIden)]
enum Users {
    Table,
    Id,
}
