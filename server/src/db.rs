use sea_orm::{Database, DatabaseConnection, DbErr, Statement, ConnectionTrait};

pub async fn establish_connection(
    database_url: &str,
    db_encryption_key: &str,
) -> Result<DatabaseConnection, DbErr> {
    tracing::info!("Connecting to database: {}", database_url);

    let db = Database::connect(database_url).await?;

    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!("PRAGMA key = '{}'", db_encryption_key),
    ))
    .await?;

    tracing::info!("Database connection established successfully");
    Ok(db)
}
