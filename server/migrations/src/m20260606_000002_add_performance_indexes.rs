use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_index(
                Index::create()
                    .name("idx_assignment_submissions_assignment_student")
                    .table(AssignmentSubmissions::Table)
                    .col(AssignmentSubmissions::AssignmentId)
                    .col(AssignmentSubmissions::StudentId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assignment_submissions_assignment_status")
                    .table(AssignmentSubmissions::Table)
                    .col(AssignmentSubmissions::AssignmentId)
                    .col(AssignmentSubmissions::Status)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_period_grades_student_class")
                    .table(PeriodGrades::Table)
                    .col(PeriodGrades::StudentId)
                    .col(PeriodGrades::ClassId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_period_grades_class_period")
                    .table(PeriodGrades::Table)
                    .col(PeriodGrades::ClassId)
                    .col(PeriodGrades::GradingPeriodNumber)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_index(
                Index::drop()
                    .name("idx_assignment_submissions_assignment_student")
                    .table(AssignmentSubmissions::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assignment_submissions_assignment_status")
                    .table(AssignmentSubmissions::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_period_grades_student_class")
                    .table(PeriodGrades::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_period_grades_class_period")
                    .table(PeriodGrades::Table)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum AssignmentSubmissions {
    Table,
    AssignmentId,
    StudentId,
    Status,
}

#[derive(DeriveIden)]
enum PeriodGrades {
    Table,
    StudentId,
    ClassId,
    GradingPeriodNumber,
}
