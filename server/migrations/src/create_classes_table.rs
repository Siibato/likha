use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(Classes::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(Classes::Id).uuid().not_null().primary_key())
                    .col(
                        ColumnDef::new(Classes::Title)
                            .string_len(255)
                            .not_null(),
                    )
                    .col(ColumnDef::new(Classes::Description).text().null())
                    .col(ColumnDef::new(Classes::TeacherId).uuid().not_null())
                    .col(
                        ColumnDef::new(Classes::IsArchived)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(Classes::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(Classes::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_classes_teacher")
                            .from(Classes::Table, Classes::TeacherId)
                            .to(Users::Table, Users::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_classes_teacher_id")
                    .table(Classes::Table)
                    .col(Classes::TeacherId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(Classes::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum Classes {
    Table,
    Id,
    Title,
    Description,
    TeacherId,
    IsArchived,
    CreatedAt,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum Users {
    Table,
    Id,
}
