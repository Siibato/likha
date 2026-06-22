use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        add_updated_at(manager, AnswerKeys::Table, AnswerKeys::UpdatedAt).await?;
        add_updated_at(manager, QuestionChoices::Table, QuestionChoices::UpdatedAt).await?;
        add_updated_at(manager, SubmissionAnswers::Table, SubmissionAnswers::UpdatedAt).await?;
        add_updated_at(manager, SubmissionAnswerItems::Table, SubmissionAnswerItems::UpdatedAt).await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        drop_updated_at(manager, AnswerKeys::Table, AnswerKeys::UpdatedAt).await?;
        drop_updated_at(manager, QuestionChoices::Table, QuestionChoices::UpdatedAt).await?;
        drop_updated_at(manager, SubmissionAnswers::Table, SubmissionAnswers::UpdatedAt).await?;
        drop_updated_at(manager, SubmissionAnswerItems::Table, SubmissionAnswerItems::UpdatedAt).await
    }
}

async fn add_updated_at(
    manager: &SchemaManager<'_>,
    table: impl Iden + 'static,
    column: impl Iden + 'static,
) -> Result<(), DbErr> {
    manager
        .alter_table(
            Table::alter()
                .table(table)
                .add_column(
                    ColumnDef::new(column)
                        .timestamp()
                        .not_null()
                        .default(Expr::current_timestamp()),
                )
                .to_owned(),
        )
        .await
}

async fn drop_updated_at(
    manager: &SchemaManager<'_>,
    table: impl Iden + 'static,
    column: impl Iden + 'static,
) -> Result<(), DbErr> {
    manager
        .alter_table(
            Table::alter()
                .table(table)
                .drop_column(column)
                .to_owned(),
        )
        .await
}

#[derive(DeriveIden)]
enum AnswerKeys {
    Table,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum QuestionChoices {
    Table,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum SubmissionAnswers {
    Table,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum SubmissionAnswerItems {
    Table,
    UpdatedAt,
}
