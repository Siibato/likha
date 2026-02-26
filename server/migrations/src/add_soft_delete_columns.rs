use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Add deleted_at to classes
        manager
            .alter_table(
                Table::alter()
                    .table(Classes::Table)
                    .add_column(ColumnDef::new(Classes::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        // Create index on classes.deleted_at for soft delete queries
        manager
            .create_index(
                Index::create()
                    .name("idx_classes_deleted_at")
                    .table(Classes::Table)
                    .col(Classes::DeletedAt)
                    .to_owned(),
            )
            .await?;

        // Add deleted_at to assessments
        manager
            .alter_table(
                Table::alter()
                    .table(Assessments::Table)
                    .add_column(ColumnDef::new(Assessments::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assessments_deleted_at")
                    .table(Assessments::Table)
                    .col(Assessments::DeletedAt)
                    .to_owned(),
            )
            .await?;

        // Add deleted_at to assignments
        manager
            .alter_table(
                Table::alter()
                    .table(Assignments::Table)
                    .add_column(ColumnDef::new(Assignments::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assignments_deleted_at")
                    .table(Assignments::Table)
                    .col(Assignments::DeletedAt)
                    .to_owned(),
            )
            .await?;

        // Add deleted_at to learning_materials
        manager
            .alter_table(
                Table::alter()
                    .table(LearningMaterials::Table)
                    .add_column(ColumnDef::new(LearningMaterials::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_learning_materials_deleted_at")
                    .table(LearningMaterials::Table)
                    .col(LearningMaterials::DeletedAt)
                    .to_owned(),
            )
            .await?;

        // Add deleted_at to assessment_questions
        manager
            .alter_table(
                Table::alter()
                    .table(AssessmentQuestions::Table)
                    .add_column(ColumnDef::new(AssessmentQuestions::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assessment_questions_deleted_at")
                    .table(AssessmentQuestions::Table)
                    .col(AssessmentQuestions::DeletedAt)
                    .to_owned(),
            )
            .await?;

        // Add deleted_at to assessment_submissions
        manager
            .alter_table(
                Table::alter()
                    .table(AssessmentSubmissions::Table)
                    .add_column(ColumnDef::new(AssessmentSubmissions::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assessment_submissions_deleted_at")
                    .table(AssessmentSubmissions::Table)
                    .col(AssessmentSubmissions::DeletedAt)
                    .to_owned(),
            )
            .await?;

        // Add deleted_at to assignment_submissions
        manager
            .alter_table(
                Table::alter()
                    .table(AssignmentSubmissions::Table)
                    .add_column(ColumnDef::new(AssignmentSubmissions::DeletedAt).timestamp().null())
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_assignment_submissions_deleted_at")
                    .table(AssignmentSubmissions::Table)
                    .col(AssignmentSubmissions::DeletedAt)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Drop all indexes first
        manager
            .drop_index(
                Index::drop()
                    .name("idx_classes_deleted_at")
                    .table(Classes::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assessments_deleted_at")
                    .table(Assessments::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assignments_deleted_at")
                    .table(Assignments::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_learning_materials_deleted_at")
                    .table(LearningMaterials::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assessment_questions_deleted_at")
                    .table(AssessmentQuestions::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assessment_submissions_deleted_at")
                    .table(AssessmentSubmissions::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assignment_submissions_deleted_at")
                    .table(AssignmentSubmissions::Table)
                    .to_owned(),
            )
            .await?;

        // Drop all columns
        manager
            .alter_table(
                Table::alter()
                    .table(Classes::Table)
                    .drop_column(Classes::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(Assessments::Table)
                    .drop_column(Assessments::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(Assignments::Table)
                    .drop_column(Assignments::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(LearningMaterials::Table)
                    .drop_column(LearningMaterials::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(AssessmentQuestions::Table)
                    .drop_column(AssessmentQuestions::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(AssessmentSubmissions::Table)
                    .drop_column(AssessmentSubmissions::DeletedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(AssignmentSubmissions::Table)
                    .drop_column(AssignmentSubmissions::DeletedAt)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum Classes {
    Table,
    DeletedAt,
}

#[derive(DeriveIden)]
enum Assessments {
    Table,
    DeletedAt,
}

#[derive(DeriveIden)]
enum Assignments {
    Table,
    DeletedAt,
}

#[derive(DeriveIden)]
enum LearningMaterials {
    Table,
    DeletedAt,
}

#[derive(DeriveIden)]
enum AssessmentQuestions {
    Table,
    DeletedAt,
}

#[derive(DeriveIden)]
enum AssessmentSubmissions {
    Table,
    DeletedAt,
}

#[derive(DeriveIden)]
enum AssignmentSubmissions {
    Table,
    DeletedAt,
}
