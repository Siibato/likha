use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // 1. assessments
        manager
            .create_table(
                Table::create()
                    .table(Assessments::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(Assessments::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(Assessments::ClassId).uuid().not_null())
                    .col(ColumnDef::new(Assessments::Title).string_len(255).not_null())
                    .col(ColumnDef::new(Assessments::Description).text().null())
                    .col(ColumnDef::new(Assessments::TimeLimitMinutes).integer().not_null())
                    .col(ColumnDef::new(Assessments::OpenAt).timestamp().not_null())
                    .col(ColumnDef::new(Assessments::CloseAt).timestamp().not_null())
                    .col(
                        ColumnDef::new(Assessments::ShowResultsImmediately)
                            .boolean()
                            .not_null()
                            .default(true),
                    )
                    .col(
                        ColumnDef::new(Assessments::ResultsReleased)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(Assessments::IsPublished)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(Assessments::TotalPoints)
                            .integer()
                            .not_null()
                            .default(0),
                    )
                    .col(
                        ColumnDef::new(Assessments::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(Assessments::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_assessments_class")
                            .from(Assessments::Table, Assessments::ClassId)
                            .to(Classes::Table, Classes::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assessments_class_id")
                    .table(Assessments::Table)
                    .col(Assessments::ClassId)
                    .to_owned(),
            )
            .await?;

        // 2. assessment_questions
        manager
            .create_table(
                Table::create()
                    .table(AssessmentQuestions::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(AssessmentQuestions::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(AssessmentQuestions::AssessmentId).uuid().not_null())
                    .col(ColumnDef::new(AssessmentQuestions::QuestionType).string_len(50).not_null())
                    .col(ColumnDef::new(AssessmentQuestions::QuestionText).text().not_null())
                    .col(ColumnDef::new(AssessmentQuestions::Points).integer().not_null())
                    .col(ColumnDef::new(AssessmentQuestions::OrderIndex).integer().not_null())
                    .col(
                        ColumnDef::new(AssessmentQuestions::IsMultiSelect)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(AssessmentQuestions::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_questions_assessment")
                            .from(AssessmentQuestions::Table, AssessmentQuestions::AssessmentId)
                            .to(Assessments::Table, Assessments::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_questions_assessment_id")
                    .table(AssessmentQuestions::Table)
                    .col(AssessmentQuestions::AssessmentId)
                    .to_owned(),
            )
            .await?;

        // 3. question_choices
        manager
            .create_table(
                Table::create()
                    .table(QuestionChoices::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(QuestionChoices::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(QuestionChoices::QuestionId).uuid().not_null())
                    .col(ColumnDef::new(QuestionChoices::ChoiceText).text().not_null())
                    .col(
                        ColumnDef::new(QuestionChoices::IsCorrect)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(ColumnDef::new(QuestionChoices::OrderIndex).integer().not_null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_choices_question")
                            .from(QuestionChoices::Table, QuestionChoices::QuestionId)
                            .to(AssessmentQuestions::Table, AssessmentQuestions::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_choices_question_id")
                    .table(QuestionChoices::Table)
                    .col(QuestionChoices::QuestionId)
                    .to_owned(),
            )
            .await?;

        // 4. question_correct_answers
        manager
            .create_table(
                Table::create()
                    .table(QuestionCorrectAnswers::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(QuestionCorrectAnswers::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(QuestionCorrectAnswers::QuestionId).uuid().not_null())
                    .col(ColumnDef::new(QuestionCorrectAnswers::AnswerText).text().not_null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_correct_answers_question")
                            .from(QuestionCorrectAnswers::Table, QuestionCorrectAnswers::QuestionId)
                            .to(AssessmentQuestions::Table, AssessmentQuestions::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_correct_answers_question_id")
                    .table(QuestionCorrectAnswers::Table)
                    .col(QuestionCorrectAnswers::QuestionId)
                    .to_owned(),
            )
            .await?;

        // 5. enumeration_items
        manager
            .create_table(
                Table::create()
                    .table(EnumerationItems::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(EnumerationItems::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(EnumerationItems::QuestionId).uuid().not_null())
                    .col(ColumnDef::new(EnumerationItems::OrderIndex).integer().not_null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_enum_items_question")
                            .from(EnumerationItems::Table, EnumerationItems::QuestionId)
                            .to(AssessmentQuestions::Table, AssessmentQuestions::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_enum_items_question_id")
                    .table(EnumerationItems::Table)
                    .col(EnumerationItems::QuestionId)
                    .to_owned(),
            )
            .await?;

        // 6. enumeration_item_answers
        manager
            .create_table(
                Table::create()
                    .table(EnumerationItemAnswers::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(EnumerationItemAnswers::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(EnumerationItemAnswers::EnumerationItemId).uuid().not_null())
                    .col(ColumnDef::new(EnumerationItemAnswers::AnswerText).text().not_null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_enum_item_answers_item")
                            .from(EnumerationItemAnswers::Table, EnumerationItemAnswers::EnumerationItemId)
                            .to(EnumerationItems::Table, EnumerationItems::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_enum_item_answers_item_id")
                    .table(EnumerationItemAnswers::Table)
                    .col(EnumerationItemAnswers::EnumerationItemId)
                    .to_owned(),
            )
            .await?;

        // 7. assessment_submissions
        manager
            .create_table(
                Table::create()
                    .table(AssessmentSubmissions::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(AssessmentSubmissions::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(AssessmentSubmissions::AssessmentId).uuid().not_null())
                    .col(ColumnDef::new(AssessmentSubmissions::StudentId).uuid().not_null())
                    .col(
                        ColumnDef::new(AssessmentSubmissions::StartedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(ColumnDef::new(AssessmentSubmissions::SubmittedAt).timestamp().null())
                    .col(
                        ColumnDef::new(AssessmentSubmissions::AutoScore)
                            .double()
                            .not_null()
                            .default(0.0),
                    )
                    .col(
                        ColumnDef::new(AssessmentSubmissions::FinalScore)
                            .double()
                            .not_null()
                            .default(0.0),
                    )
                    .col(
                        ColumnDef::new(AssessmentSubmissions::IsSubmitted)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(AssessmentSubmissions::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_submissions_assessment")
                            .from(AssessmentSubmissions::Table, AssessmentSubmissions::AssessmentId)
                            .to(Assessments::Table, Assessments::Id),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_submissions_student")
                            .from(AssessmentSubmissions::Table, AssessmentSubmissions::StudentId)
                            .to(Users::Table, Users::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_submissions_assessment_id")
                    .table(AssessmentSubmissions::Table)
                    .col(AssessmentSubmissions::AssessmentId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_submissions_student_id")
                    .table(AssessmentSubmissions::Table)
                    .col(AssessmentSubmissions::StudentId)
                    .to_owned(),
            )
            .await?;

        // 8. submission_answers
        manager
            .create_table(
                Table::create()
                    .table(SubmissionAnswers::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(SubmissionAnswers::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(SubmissionAnswers::SubmissionId).uuid().not_null())
                    .col(ColumnDef::new(SubmissionAnswers::QuestionId).uuid().not_null())
                    .col(ColumnDef::new(SubmissionAnswers::AnswerText).text().null())
                    .col(ColumnDef::new(SubmissionAnswers::IsAutoCorrect).boolean().null())
                    .col(ColumnDef::new(SubmissionAnswers::IsOverrideCorrect).boolean().null())
                    .col(
                        ColumnDef::new(SubmissionAnswers::PointsAwarded)
                            .double()
                            .not_null()
                            .default(0.0),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_answers_submission")
                            .from(SubmissionAnswers::Table, SubmissionAnswers::SubmissionId)
                            .to(AssessmentSubmissions::Table, AssessmentSubmissions::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_answers_question")
                            .from(SubmissionAnswers::Table, SubmissionAnswers::QuestionId)
                            .to(AssessmentQuestions::Table, AssessmentQuestions::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sub_answers_submission_id")
                    .table(SubmissionAnswers::Table)
                    .col(SubmissionAnswers::SubmissionId)
                    .to_owned(),
            )
            .await?;

        // 9. submission_answer_choices
        manager
            .create_table(
                Table::create()
                    .table(SubmissionAnswerChoices::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(SubmissionAnswerChoices::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(SubmissionAnswerChoices::SubmissionAnswerId).uuid().not_null())
                    .col(ColumnDef::new(SubmissionAnswerChoices::ChoiceId).uuid().not_null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_answer_choices_answer")
                            .from(SubmissionAnswerChoices::Table, SubmissionAnswerChoices::SubmissionAnswerId)
                            .to(SubmissionAnswers::Table, SubmissionAnswers::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_answer_choices_choice")
                            .from(SubmissionAnswerChoices::Table, SubmissionAnswerChoices::ChoiceId)
                            .to(QuestionChoices::Table, QuestionChoices::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sub_answer_choices_answer_id")
                    .table(SubmissionAnswerChoices::Table)
                    .col(SubmissionAnswerChoices::SubmissionAnswerId)
                    .to_owned(),
            )
            .await?;

        // 10. submission_enumeration_answers
        manager
            .create_table(
                Table::create()
                    .table(SubmissionEnumerationAnswers::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(SubmissionEnumerationAnswers::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(SubmissionEnumerationAnswers::SubmissionAnswerId).uuid().not_null())
                    .col(ColumnDef::new(SubmissionEnumerationAnswers::AnswerText).text().not_null())
                    .col(ColumnDef::new(SubmissionEnumerationAnswers::MatchedItemId).uuid().null())
                    .col(ColumnDef::new(SubmissionEnumerationAnswers::IsAutoCorrect).boolean().null())
                    .col(ColumnDef::new(SubmissionEnumerationAnswers::IsOverrideCorrect).boolean().null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_enum_answers_answer")
                            .from(SubmissionEnumerationAnswers::Table, SubmissionEnumerationAnswers::SubmissionAnswerId)
                            .to(SubmissionAnswers::Table, SubmissionAnswers::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_enum_answers_item")
                            .from(SubmissionEnumerationAnswers::Table, SubmissionEnumerationAnswers::MatchedItemId)
                            .to(EnumerationItems::Table, EnumerationItems::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sub_enum_answers_answer_id")
                    .table(SubmissionEnumerationAnswers::Table)
                    .col(SubmissionEnumerationAnswers::SubmissionAnswerId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.drop_table(Table::drop().table(SubmissionEnumerationAnswers::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(SubmissionAnswerChoices::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(SubmissionAnswers::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(AssessmentSubmissions::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(EnumerationItemAnswers::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(EnumerationItems::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(QuestionCorrectAnswers::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(QuestionChoices::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(AssessmentQuestions::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(Assessments::Table).to_owned()).await
    }
}

#[derive(DeriveIden)]
enum Assessments {
    Table,
    Id,
    ClassId,
    Title,
    Description,
    TimeLimitMinutes,
    OpenAt,
    CloseAt,
    ShowResultsImmediately,
    ResultsReleased,
    IsPublished,
    TotalPoints,
    CreatedAt,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum AssessmentQuestions {
    Table,
    Id,
    AssessmentId,
    QuestionType,
    QuestionText,
    Points,
    OrderIndex,
    IsMultiSelect,
    CreatedAt,
}

#[derive(DeriveIden)]
enum QuestionChoices {
    Table,
    Id,
    QuestionId,
    ChoiceText,
    IsCorrect,
    OrderIndex,
}

#[derive(DeriveIden)]
enum QuestionCorrectAnswers {
    Table,
    Id,
    QuestionId,
    AnswerText,
}

#[derive(DeriveIden)]
enum EnumerationItems {
    Table,
    Id,
    QuestionId,
    OrderIndex,
}

#[derive(DeriveIden)]
enum EnumerationItemAnswers {
    Table,
    Id,
    EnumerationItemId,
    AnswerText,
}

#[derive(DeriveIden)]
enum AssessmentSubmissions {
    Table,
    Id,
    AssessmentId,
    StudentId,
    StartedAt,
    SubmittedAt,
    AutoScore,
    FinalScore,
    IsSubmitted,
    CreatedAt,
}

#[derive(DeriveIden)]
enum SubmissionAnswers {
    Table,
    Id,
    SubmissionId,
    QuestionId,
    AnswerText,
    IsAutoCorrect,
    IsOverrideCorrect,
    PointsAwarded,
}

#[derive(DeriveIden)]
enum SubmissionAnswerChoices {
    Table,
    Id,
    SubmissionAnswerId,
    ChoiceId,
}

#[derive(DeriveIden)]
enum SubmissionEnumerationAnswers {
    Table,
    Id,
    SubmissionAnswerId,
    AnswerText,
    MatchedItemId,
    IsAutoCorrect,
    IsOverrideCorrect,
}

#[derive(DeriveIden)]
enum Classes {
    Table,
    Id,
}

#[derive(DeriveIden)]
enum Users {
    Table,
    Id,
}
