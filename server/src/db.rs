use sea_orm::{ConnectOptions, Database, DatabaseConnection, DbErr, Statement, ConnectionTrait};
use std::time::Duration;

pub async fn establish_connection(
    database_url: &str,
    db_encryption_key: &str,
) -> Result<DatabaseConnection, DbErr> {
    tracing::info!("Connecting to database: {}", database_url);

    let mut opt = ConnectOptions::new(database_url.to_owned());
    opt.max_connections(5)
        .min_connections(5)
        .connect_timeout(Duration::from_secs(10))
        .idle_timeout(Duration::from_secs(300))
        .max_lifetime(Duration::from_secs(1800));

    let db = Database::connect(opt).await?;

    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!("PRAGMA key = '{}'", db_encryption_key),
    ))
    .await?;

    let pragmas = vec![
        "PRAGMA journal_mode = WAL",
        "PRAGMA synchronous = NORMAL",
        "PRAGMA temp_store = memory",
        "PRAGMA mmap_size = 268435456",
        "PRAGMA busy_timeout = 10000",
    ];

    for pragma in pragmas {
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            pragma.to_string(),
        ))
        .await?;
    }

    tracing::info!("Database connection established successfully with WAL mode and pool size 50");
    Ok(db)
}
