use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(ClassEnrollments::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ClassEnrollments::Id)
                            .uuid()
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(ClassEnrollments::ClassId)
                            .uuid()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ClassEnrollments::StudentId)
                            .uuid()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ClassEnrollments::EnrolledAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(ClassEnrollments::RemovedAt)
                            .timestamp()
                            .null(),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_enrollments_class")
                            .from(ClassEnrollments::Table, ClassEnrollments::ClassId)
                            .to(Classes::Table, Classes::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_enrollments_student")
                            .from(ClassEnrollments::Table, ClassEnrollments::StudentId)
                            .to(Users::Table, Users::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_enrollments_class_id")
                    .table(ClassEnrollments::Table)
                    .col(ClassEnrollments::ClassId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_enrollments_student_id")
                    .table(ClassEnrollments::Table)
                    .col(ClassEnrollments::StudentId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(ClassEnrollments::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum ClassEnrollments {
    Table,
    Id,
    ClassId,
    StudentId,
    EnrolledAt,
    RemovedAt,
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
