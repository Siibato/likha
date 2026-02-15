use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Add last_modified_at to classes
        manager
            .alter_table(
                Table::alter()
                    .table(Classes::Table)
                    .add_column(
                        ColumnDef::new(Classes::LastModifiedAt)
                            .timestamp()
                            .null(),
                    )
                    .to_owned(),
            )
            .await?;

        // Create index on classes.last_modified_at
        manager
            .create_index(
                Index::create()
                    .name("idx_classes_last_modified_at")
                    .table(Classes::Table)
                    .col(Classes::LastModifiedAt)
                    .to_owned(),
            )
            .await?;

        // Add last_modified_at to assessments
        manager
            .alter_table(
                Table::alter()
                    .table(Assessments::Table)
                    .add_column(
                        ColumnDef::new(Assessments::LastModifiedAt)
                            .timestamp()
                            .null(),
                    )
                    .to_owned(),
            )
            .await?;

        // Create index on assessments.last_modified_at
        manager
            .create_index(
                Index::create()
                    .name("idx_assessments_last_modified_at")
                    .table(Assessments::Table)
                    .col(Assessments::LastModifiedAt)
                    .to_owned(),
            )
            .await?;

        // Add last_modified_at to assignments
        manager
            .alter_table(
                Table::alter()
                    .table(Assignments::Table)
                    .add_column(
                        ColumnDef::new(Assignments::LastModifiedAt)
                            .timestamp()
                            .null(),
                    )
                    .to_owned(),
            )
            .await?;

        // Create index on assignments.last_modified_at
        manager
            .create_index(
                Index::create()
                    .name("idx_assignments_last_modified_at")
                    .table(Assignments::Table)
                    .col(Assignments::LastModifiedAt)
                    .to_owned(),
            )
            .await?;

        // Add last_modified_at to learning_materials
        manager
            .alter_table(
                Table::alter()
                    .table(LearningMaterials::Table)
                    .add_column(
                        ColumnDef::new(LearningMaterials::LastModifiedAt)
                            .timestamp()
                            .null(),
                    )
                    .to_owned(),
            )
            .await?;

        // Create index on learning_materials.last_modified_at
        manager
            .create_index(
                Index::create()
                    .name("idx_learning_materials_last_modified_at")
                    .table(LearningMaterials::Table)
                    .col(LearningMaterials::LastModifiedAt)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Drop indexes first
        manager
            .drop_index(
                Index::drop()
                    .name("idx_classes_last_modified_at")
                    .table(Classes::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assessments_last_modified_at")
                    .table(Assessments::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_assignments_last_modified_at")
                    .table(Assignments::Table)
                    .to_owned(),
            )
            .await?;

        manager
            .drop_index(
                Index::drop()
                    .name("idx_learning_materials_last_modified_at")
                    .table(LearningMaterials::Table)
                    .to_owned(),
            )
            .await?;

        // Drop columns
        manager
            .alter_table(
                Table::alter()
                    .table(Classes::Table)
                    .drop_column(Classes::LastModifiedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(Assessments::Table)
                    .drop_column(Assessments::LastModifiedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(Assignments::Table)
                    .drop_column(Assignments::LastModifiedAt)
                    .to_owned(),
            )
            .await?;

        manager
            .alter_table(
                Table::alter()
                    .table(LearningMaterials::Table)
                    .drop_column(LearningMaterials::LastModifiedAt)
                    .to_owned(),
            )
            .await
    }
}

#[derive(DeriveIden)]
enum Classes {
    Table,
    LastModifiedAt,
}

#[derive(DeriveIden)]
enum Assessments {
    Table,
    LastModifiedAt,
}

#[derive(DeriveIden)]
enum Assignments {
    Table,
    LastModifiedAt,
}

#[derive(DeriveIden)]
enum LearningMaterials {
    Table,
    LastModifiedAt,
}
