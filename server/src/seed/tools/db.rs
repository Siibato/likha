use sea_orm::{ConnectionTrait, DatabaseConnection, DbErr, Statement};

pub async fn disable_foreign_keys(db: &DatabaseConnection) -> Result<(), DbErr> {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "PRAGMA foreign_keys = OFF".to_string(),
    ))
    .await?;
    Ok(())
}

pub async fn enable_foreign_keys(db: &DatabaseConnection) -> Result<(), DbErr> {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "PRAGMA foreign_keys = ON".to_string(),
    ))
    .await?;
    Ok(())
}
