use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .alter_table(
                Table::alter()
                    .table(LearnerDetails::Table)
                    .drop_column(LearnerDetails::Age)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .alter_table(
                Table::alter()
                    .table(LearnerDetails::Table)
                    .add_column(
                        ColumnDef::new(LearnerDetails::Age)
                            .integer()
                            .null(),
                    )
                    .to_owned(),
            )
            .await
    }
}

#[derive(Iden)]
enum LearnerDetails {
    Table,
    Age,
}
