use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // 1. learning_materials
        manager
            .create_table(
                Table::create()
                    .table(LearningMaterials::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(LearningMaterials::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(LearningMaterials::ClassId).uuid().not_null())
                    .col(ColumnDef::new(LearningMaterials::Title).string_len(200).not_null())
                    .col(ColumnDef::new(LearningMaterials::Description).text().null())
                    .col(ColumnDef::new(LearningMaterials::ContentText).text().null())
                    .col(ColumnDef::new(LearningMaterials::OrderIndex).integer().not_null())
                    .col(
                        ColumnDef::new(LearningMaterials::CreatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(LearningMaterials::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_learning_materials_class")
                            .from(LearningMaterials::Table, LearningMaterials::ClassId)
                            .to(Classes::Table, Classes::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_learning_materials_class_id")
                    .table(LearningMaterials::Table)
                    .col(LearningMaterials::ClassId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_learning_materials_class_order")
                    .table(LearningMaterials::Table)
                    .col(LearningMaterials::ClassId)
                    .col(LearningMaterials::OrderIndex)
                    .to_owned(),
            )
            .await?;

        // 2. material_files
        manager
            .create_table(
                Table::create()
                    .table(MaterialFiles::Table)
                    .if_not_exists()
                    .col(ColumnDef::new(MaterialFiles::Id).uuid().not_null().primary_key())
                    .col(ColumnDef::new(MaterialFiles::MaterialId).uuid().not_null())
                    .col(ColumnDef::new(MaterialFiles::FileName).string_len(255).not_null())
                    .col(ColumnDef::new(MaterialFiles::FileType).string_len(100).not_null())
                    .col(ColumnDef::new(MaterialFiles::FileSize).big_integer().not_null())
                    .col(ColumnDef::new(MaterialFiles::FileData).binary().not_null())
                    .col(
                        ColumnDef::new(MaterialFiles::UploadedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_material_files_material")
                            .from(MaterialFiles::Table, MaterialFiles::MaterialId)
                            .to(LearningMaterials::Table, LearningMaterials::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_material_files_material_id")
                    .table(MaterialFiles::Table)
                    .col(MaterialFiles::MaterialId)
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.drop_table(Table::drop().table(MaterialFiles::Table).to_owned()).await?;
        manager.drop_table(Table::drop().table(LearningMaterials::Table).to_owned()).await
    }
}

#[derive(DeriveIden)]
enum LearningMaterials {
    Table,
    Id,
    ClassId,
    Title,
    Description,
    ContentText,
    OrderIndex,
    CreatedAt,
    UpdatedAt,
}

#[derive(DeriveIden)]
enum MaterialFiles {
    Table,
    Id,
    MaterialId,
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
