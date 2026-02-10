use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // 1. assignments
        manager
            .create_table(
                Table::create()
                    .table(Assignments::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(Assignments::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(Assignments::ClassId).uuid().not_null())
                    .col(ColumnDef::new(Assignments::Title).string_len(200).not_null())
                    .col(ColumnDef::new(Assignments::Instructions).text().not_null())
                    .col(ColumnDef::new(Assignments::TotalPoints).integer().not_null())
                    .col(ColumnDef::new(Assignments::SubmissionType).string_len(50).not_null())
                    .col(ColumnDef::new(Assignments::AllowedFileTypes).text().null())
                    .col(ColumnDef::new(Assignments::MaxFileSizeMb).integer().null())
                    .col(ColumnDef::new(Assignments::DueAt).timestamp().not_null())
                    .col(
                        ColumnDef::new(Assignments::IsPublished)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(
                        ColumnDef::new(Assignments::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(Assignments::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_assignments_class")
                            .from(Assignments::Table, Assignments::ClassId)
                            .to(Classes::Table, Classes::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assignments_class_id")
                    .table(Assignments::Table)
                    .col(Assignments::ClassId)
                    .to_owned(),
            )
            .await?;

        // 2. assignment_submissions
        manager
            .create_table(
                Table::create()
                    .table(AssignmentSubmissions::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(AssignmentSubmissions::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(AssignmentSubmissions::AssignmentId).uuid().not_null())
                    .col(ColumnDef::new(AssignmentSubmissions::StudentId).uuid().not_null())
                    .col(
                        ColumnDef::new(AssignmentSubmissions::Status)
                            .string_len(20)
                            .not_null()
                            .default("draft"),
                    )
                    .col(ColumnDef::new(AssignmentSubmissions::TextContent).text().null())
                    .col(ColumnDef::new(AssignmentSubmissions::SubmittedAt).timestamp().null())
                    .col(
                        ColumnDef::new(AssignmentSubmissions::IsLate)
                            .boolean()
                            .not_null()
                            .default(false),
                    )
                    .col(ColumnDef::new(AssignmentSubmissions::Score).integer().null())
                    .col(ColumnDef::new(AssignmentSubmissions::Feedback).text().null())
                    .col(ColumnDef::new(AssignmentSubmissions::GradedAt).timestamp().null())
                    .col(
                        ColumnDef::new(AssignmentSubmissions::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(AssignmentSubmissions::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_asn_submissions_assignment")
                            .from(AssignmentSubmissions::Table, AssignmentSubmissions::AssignmentId)
                            .to(Assignments::Table, Assignments::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_asn_submissions_student")
                            .from(AssignmentSubmissions::Table, AssignmentSubmissions::StudentId)
                            .to(Users::Table, Users::Id),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_asn_submissions_assignment_id")
                    .table(AssignmentSubmissions::Table)
                    .col(AssignmentSubmissions::AssignmentId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_asn_submissions_student_id")
                    .table(AssignmentSubmissions::Table)
                    .col(AssignmentSubmissions::StudentId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_asn_submissions_unique")
                    .table(AssignmentSubmissions::Table)
                    .col(AssignmentSubmissions::AssignmentId)
                    .col(AssignmentSubmissions::StudentId)
                    .unique()
                    .to_owned(),
            )
            .await?;

        // 3. submission_files
        manager
            .create_table(
                Table::create()
                    .table(SubmissionFiles::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(SubmissionFiles::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(SubmissionFiles::SubmissionId).uuid().not_null())
                    .col(ColumnDef::new(SubmissionFiles::FileName).string_len(255).not_null())
                    .col(ColumnDef::new(SubmissionFiles::FileType).string_len(100).not_null())
                    .col(ColumnDef::new(SubmissionFiles::FileSize).big_integer().not_null())
                    .col(ColumnDef::new(SubmissionFiles::FileData).binary().not_null())
                    .col(
                        ColumnDef::new(SubmissionFiles::UploadedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_sub_files_submission")
                            .from(SubmissionFiles::Table, SubmissionFiles::SubmissionId)
                            .to(AssignmentSubmissions::Table, AssignmentSubmissions::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_sub_files_submission_id")
                    .table(SubmissionFiles::Table)
                    .col(SubmissionFiles::SubmissionId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.drop_table(Table::drop().table(SubmissionFiles::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(AssignmentSubmissions::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(Assignments::Table).to_owned()).await
    }
}

#[derive(DeriveIden)]
enum Assignments {
    Table,
    Id,
    ClassId,
    Title,
    Instructions,
    TotalPoints,
    SubmissionType,
    AllowedFileTypes,
    MaxFileSizeMb,
    DueAt,
    IsPublished,
    CreatedAt,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum AssignmentSubmissions {
    Table,
    Id,
    AssignmentId,
    StudentId,
    Status,
    TextContent,
    SubmittedAt,
    IsLate,
    Score,
    Feedback,
    GradedAt,
    CreatedAt,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum SubmissionFiles {
    Table,
    Id,
    SubmissionId,
    FileName,
    FileType,
    FileSize,
    FileData,
    UploadedAt,
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
