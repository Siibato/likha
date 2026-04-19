use migration::{Migrator, MigratorTrait};
use sea_orm::{Database, DatabaseConnection};

/// Creates a fresh in-memory SQLite database with all migrations applied.
/// Each call returns an isolated connection — perfect for per-test isolation.
pub async fn test_db() -> DatabaseConnection {
    let db = Database::connect("sqlite::memory:")
        .await
        .expect("Failed to connect to in-memory SQLite");
    Migrator::up(&db, None)
        .await
        .expect("Failed to run migrations on test DB");
    db
}
