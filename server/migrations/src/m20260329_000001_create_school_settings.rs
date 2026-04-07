use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(SchoolSettings::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(SchoolSettings::Id)
                            .integer()
                            .not_null()
                            .primary_key()
                            .default(1),
                    )
                    .col(
                        ColumnDef::new(SchoolSettings::SchoolCode)
                            .string()
                            .not_null(),
                    )
                    .col(ColumnDef::new(SchoolSettings::SchoolName).string())
                    .col(ColumnDef::new(SchoolSettings::SchoolRegion).string())
                    .col(ColumnDef::new(SchoolSettings::SchoolDivision).string())
                    .col(ColumnDef::new(SchoolSettings::SchoolYear).string())
                    .col(
                        ColumnDef::new(SchoolSettings::UpdatedAt)
                            .date_time()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(SchoolSettings::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
pub enum SchoolSettings {
    Table,
    Id,
    SchoolCode,
    SchoolName,
    SchoolRegion,
    SchoolDivision,
    SchoolYear,
    UpdatedAt,
}
