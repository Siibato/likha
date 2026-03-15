use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(LoginAttempts::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(LoginAttempts::Id)
                            .uuid()
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(LoginAttempts::Username)
                            .string_len(50)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(LoginAttempts::IpAddress)
                            .string_len(45)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(LoginAttempts::AttemptCount)
                            .integer()
                            .not_null()
                            .default(1),
                    )
                    .col(
                        ColumnDef::new(LoginAttempts::FirstAttemptAt)
                            .timestamp()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(LoginAttempts::LastAttemptAt)
                            .timestamp()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(LoginAttempts::LockedUntil)
                            .timestamp(),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_login_attempts_username")
                    .table(LoginAttempts::Table)
                    .col(LoginAttempts::Username)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_login_attempts_username_ip")
                    .table(LoginAttempts::Table)
                    .col(LoginAttempts::Username)
                    .col(LoginAttempts::IpAddress)
                    .unique()
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(LoginAttempts::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum LoginAttempts {
    Table,
    Id,
    Username,
    IpAddress,
    AttemptCount,
    FirstAttemptAt,
    LastAttemptAt,
    LockedUntil,
}
