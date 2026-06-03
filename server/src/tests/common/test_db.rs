use migration::{Migrator, MigratorTrait};
use sea_orm::{Database, DatabaseConnection};

/// Creates a fresh in-memory SQLite database with all migrations applied.
/// Each call returns an isolated connection — perfect for per-test isolation.
/// Accepts a db_encryption_key to match the new establish_connection signature.
pub async fn test_db_with_key(db_encryption_key: &str) -> DatabaseConnection {
    // In-memory SQLite ignores SQLCipher PRAGMA key, so we pass the key for API compatibility.
    let db = Database::connect("sqlite::memory:")
        .await
        .expect("Failed to connect to in-memory SQLite");
    Migrator::up(&db, None)
        .await
        .expect("Failed to run migrations on test DB");
    db
}

/// Compatibility function for existing tests that call test_db() without a key.
/// Uses a default test key; in-memory DB ignores the key anyway.
pub async fn test_db() -> DatabaseConnection {
    test_db_with_key("test_key").await
}
