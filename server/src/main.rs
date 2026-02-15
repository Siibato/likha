mod config;
mod db;
mod handlers;
mod middleware;
mod models;
mod routes;
mod schema;
mod services;
mod utils;

use axum::Router;
use chrono::Utc;
use dotenv::dotenv;
use sea_orm::{DatabaseConnection, EntityTrait, QueryFilter, ColumnTrait, ActiveModelTrait, Set};
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use uuid::Uuid;

use crate::services::assessment_service::AssessmentService;
use crate::services::assignment_service::AssignmentService;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;
use crate::services::learning_material_service::LearningMaterialService;
use crate::services::sync_service::SyncService;

#[tokio::main]
async fn main() {
    dotenv().ok();

    tracing_subscriber::fmt()
        .with_target(false)
        .compact()
        .init();

    let config = config::ServerConfig::from_env();
    let args: Vec<String> = std::env::args().collect();

    if args.len() > 1 {
        match args[1].as_str() {
            "delete-db" => {
                let db_path = config.database_url
                    .replace("sqlite://", "")
                    .replace("sqlite:", "")
                    .split('?')
                    .next()
                    .unwrap_or("")
                    .to_string();

                if db_path.is_empty() || db_path == ":memory:" {
                    eprintln!("Cannot delete in-memory database");
                    std::process::exit(1);
                }

                if std::path::Path::new(&db_path).exists() {
                    std::fs::remove_file(&db_path).expect("Failed to delete database file");
                    println!("Database deleted: {}", db_path);
                } else {
                    println!("Database file does not exist: {}", db_path);
                }
                return;
            }
            "create-db" => {
                println!("Creating database and running migrations...");
                let db = db::establish_connection(&config.database_url)
                    .await
                    .expect("Failed to connect to database");
                run_migrations(&db).await.expect("Failed to run migrations");
                create_or_update_database_id(&db).await.expect("Failed to create database ID");
                seed_admin(&db).await.expect("Failed to seed admin account");
                println!("Database created and migrations applied successfully");
                return;
            }
            "reset-db" => {
                let db_path = config.database_url
                    .replace("sqlite://", "")
                    .replace("sqlite:", "")
                    .split('?')
                    .next()
                    .unwrap_or("")
                    .to_string();

                if !db_path.is_empty() && db_path != ":memory:" && std::path::Path::new(&db_path).exists() {
                    std::fs::remove_file(&db_path).expect("Failed to delete database file");
                    println!("Old database deleted: {}", db_path);
                }

                println!("Creating fresh database and running migrations...");
                let db = db::establish_connection(&config.database_url)
                    .await
                    .expect("Failed to connect to database");
                run_migrations(&db).await.expect("Failed to run migrations");
                create_or_update_database_id(&db).await.expect("Failed to create database ID");
                seed_admin(&db).await.expect("Failed to seed admin account");
                println!("Database reset complete");
                return;
            }
            other => {
                eprintln!("Unknown command: {}", other);
                eprintln!("Available commands:");
                eprintln!("  create-db   Create the database and run migrations");
                eprintln!("  delete-db   Delete the database file");
                eprintln!("  reset-db    Delete and recreate the database");
                std::process::exit(1);
            }
        }
    }

    tracing::info!("Starting Offline LMS Server");
    tracing::info!("Host: {}", config.host);
    tracing::info!("Port: {}", config.port);

    // Connect to database
    let db = db::establish_connection(&config.database_url)
        .await
        .expect("Failed to connect to database");

    // Run migrations
    run_migrations(&db)
        .await
        .expect("Failed to run migrations");

    // Seed default admin account
    seed_admin(&db).await.expect("Failed to seed admin account");

    // Initialize services
    let auth_service = Arc::new(AuthService::new(
        db.clone(),
        config.jwt_secret.clone(),
        config.jwt_expiration,
    ));

    let class_service = Arc::new(ClassService::new(db.clone()));

    let assessment_service = Arc::new(AssessmentService::new(db.clone()));
    let assignment_service = Arc::new(AssignmentService::new(db.clone()));
    let material_service = Arc::new(LearningMaterialService::new(db.clone()));

    // Initialize sync service
    let sync_service = Arc::new(SyncService::new(
        db.clone(),
        auth_service.clone(),
        class_service.clone(),
        assessment_service.clone(),
        assignment_service.clone(),
        material_service.clone(),
    ));

    let app = create_app(
        auth_service,
        class_service,
        assessment_service,
        assignment_service,
        material_service,
        sync_service,
    );

    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));

    tracing::info!("Server listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind to address");

    axum::serve(listener, app)
        .await
        .expect("Failed to start server");
}

fn create_app(
    auth_service: Arc<AuthService>,
    class_service: Arc<ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    sync_service: Arc<SyncService>,
) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .nest(
            "/api/v1",
            routes::api_routes(
                auth_service,
                class_service,
                assessment_service,
                assignment_service,
                material_service,
                sync_service,
            ),
        )
        .layer(cors)
        .layer(middleware::logging_middleware())
}

async fn run_migrations(db: &DatabaseConnection) -> Result<(), sea_orm::DbErr> {
    use migration::{Migrator, MigratorTrait};

    tracing::info!("Running database migrations...");
    Migrator::up(db, None).await?;
    tracing::info!("Migrations completed successfully");

    Ok(())
}

async fn seed_admin(db: &DatabaseConnection) -> Result<(), sea_orm::DbErr> {
    use ::entity::users;

    // Check if admin already exists
    let existing_admin = users::Entity::find()
        .filter(users::Column::Role.eq("admin"))
        .one(db)
        .await?;

    if existing_admin.is_some() {
        tracing::info!("Admin account already exists, skipping seed");
        return Ok(());
    }

    // Create default admin account
    let admin = users::ActiveModel {
        id: Set(Uuid::new_v4()),
        username: Set("admin".to_string()),
        password_hash: Set(None),
        full_name: Set("System Administrator".to_string()),
        role: Set("admin".to_string()),
        account_status: Set("pending_activation".to_string()),
        is_active: Set(true),
        activated_at: Set(None),
        created_by: Set(None),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
    };

    admin.insert(db).await?;
    tracing::info!("Default admin account created (username: admin, status: pending_activation)");

    Ok(())
}

async fn create_or_update_database_id(db: &DatabaseConnection) -> Result<(), sea_orm::DbErr> {
    use ::entity::database_metadata;

    // Generate a unique database ID using UUID + timestamp
    let database_id = format!("{}-{}", Uuid::new_v4(), Utc::now().timestamp());

    // Delete existing metadata (we only keep one record)
    database_metadata::Entity::delete_many().exec(db).await?;

    // Insert new metadata with fresh database ID
    let metadata = database_metadata::ActiveModel {
        id: Set(1),
        database_id: Set(database_id.clone()),
        created_at: Set(Utc::now()),
        updated_at: Set(Utc::now()),
    };

    metadata.insert(db).await?;
    tracing::info!("Database ID created: {}", database_id);

    Ok(())
}
