mod config;
mod db;
mod handlers;
mod middleware;
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
use std::time::Duration;
use axum::http::header::{AUTHORIZATION, CONTENT_TYPE, ACCEPT, HeaderName, HeaderValue};
use axum::http::Method;
use tower_http::cors::CorsLayer;
use tower_http::limit::RequestBodyLimitLayer;
use tower_http::timeout::TimeoutLayer;
use uuid::Uuid;

use crate::services::assessment::AssessmentService;
use crate::services::assignment::AssignmentService;
use crate::services::auth::AuthService;
use crate::services::class::ClassService;
use crate::services::grade_computation::GradeComputationService;
use crate::services::learning_material::LearningMaterialService;
use crate::services::entitlement::EntitlementService;
use crate::services::setup_service::SetupService;
use crate::services::sync_push::SyncPushService;
use crate::services::sync_conflict_service::SyncConflictService;
use crate::services::sync_full::SyncFullService;
use crate::services::sync_delta::SyncDeltaService;
use crate::services::tos::TosService;
use crate::db::repositories::{
    manifest_repository::ManifestRepository,
    processed_operations_repository::ProcessedOperationsRepository,
};

#[tokio::main]
async fn main() {
    dotenv().ok();

    tracing_subscriber::fmt()
        .with_target(false)
        .compact()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
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
                let db = db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                run_migrations(&db).await.expect("Failed to run migrations");
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
                let db = db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                run_migrations(&db).await.expect("Failed to run migrations");
                seed_admin(&db).await.expect("Failed to seed admin account");
                println!("Database reset complete");
                return;
            }
            "clear-invalid-attempts" => {
                let db = db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                let repo = crate::db::repositories::login_attempt_repository::LoginAttemptRepository::new(db);
                repo.clear_all_attempts().await.expect("Failed to clear attempts");
                println!("All login attempt records cleared.");
                return;
            }
            other => {
                eprintln!("Unknown command: {}", other);
                eprintln!("Available commands:");
                eprintln!("  create-db               Create the database and run migrations");
                eprintln!("  delete-db               Delete the database file");
                eprintln!("  reset-db                Delete and recreate the database");
                eprintln!("  clear-invalid-attempts  Clear all login attempt records");
                std::process::exit(1);
            }
        }
    }

    tracing::info!("Starting Offline LMS Server");
    tracing::info!("Host: {}", config.host);
    tracing::info!("Port: {}", config.port);

    // Connect to database
    let db = db::establish_connection(&config.database_url, &config.db_encryption_key)
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
    let assignment_service = Arc::new(AssignmentService::new(db.clone(), config.file_storage_path.clone()));
    let material_service = Arc::new(LearningMaterialService::new(db.clone(), config.file_storage_path.clone()));

    // Initialize new offline-first sync services
    let _entitlement_repo = crate::db::repositories::entitlement_repository::EntitlementRepository::new(db.clone());
    let manifest_repo = ManifestRepository::new(db.clone());

    let entitlement_service = Arc::new(EntitlementService::new(db.clone()));

    let processed_ops_repo = Arc::new(ProcessedOperationsRepository::new(db.clone()));
    let grade_computation_service = Arc::new(GradeComputationService::new(db.clone()));
    let tos_service = Arc::new(TosService::new(db.clone()));

    let setup_service = Arc::new(
        SetupService::new(db.clone(), config.school_code.clone()).await,
    );

    let sync_push_service = Arc::new(SyncPushService::new(
        entitlement_service.clone(),
        class_service.clone(),
        assessment_service.clone(),
        assignment_service.clone(),
        material_service.clone(),
        auth_service.clone(),
        grade_computation_service.clone(),
        tos_service.clone(),
        processed_ops_repo,
    ));

    let sync_conflict_service = Arc::new(SyncConflictService::new());

    let sync_full_service = Arc::new(SyncFullService::new(
        entitlement_service.clone(),
        manifest_repo.clone(),
        db.clone(),
    ));

    let sync_delta_service = Arc::new(SyncDeltaService::new(
        entitlement_service.clone(),
        manifest_repo.clone(),
        db.clone(),
    ));

    let app = create_app(
        &config,
        auth_service,
        class_service,
        assessment_service,
        assignment_service,
        material_service,
        grade_computation_service,
        tos_service,
        setup_service,
        sync_push_service,
        sync_conflict_service,
        sync_full_service,
        sync_delta_service,
    );

    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));

    tracing::info!("Server listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind to address");

    axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())
        .await
        .expect("Failed to start server");
}

fn create_app(
    config: &config::ServerConfig,
    auth_service: Arc<AuthService>,
    class_service: Arc<ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    grade_computation_service: Arc<GradeComputationService>,
    tos_service: Arc<TosService>,
    setup_service: Arc<SetupService>,
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
    sync_full_service: Arc<SyncFullService>,
    sync_delta_service: Arc<SyncDeltaService>,
) -> Router {
    Router::new()
        .nest(
            "/api/v1",
            routes::api_routes(
                auth_service,
                class_service,
                assessment_service,
                assignment_service,
                material_service,
                grade_computation_service,
                tos_service,
                setup_service,
                sync_push_service,
                sync_conflict_service,
                sync_full_service,
                sync_delta_service,
            ),
        )
        .layer(RequestBodyLimitLayer::new(config.max_body_size_bytes as usize))
        .layer(TimeoutLayer::with_status_code(axum::http::StatusCode::REQUEST_TIMEOUT, Duration::from_secs(60)))
        .layer(build_cors_layer(config))
        .layer(axum::middleware::from_fn(middleware::add_security_headers))
        .layer(middleware::logging_middleware())
}

fn build_cors_layer(config: &config::ServerConfig) -> CorsLayer {
    let x_device_id: HeaderName = "x-device-id".parse().expect("valid header name");

    let allowed_methods = [
        Method::GET,
        Method::POST,
        Method::PUT,
        Method::DELETE,
        Method::OPTIONS,
    ];

    let allowed_headers = [AUTHORIZATION, CONTENT_TYPE, ACCEPT, x_device_id];

    if config.allowed_origins.is_empty() {
        return CorsLayer::new()
            .allow_methods(allowed_methods)
            .allow_headers(allowed_headers)
            .max_age(Duration::from_secs(3600));
    }

    let origins: Vec<HeaderValue> = config
        .allowed_origins
        .iter()
        .filter_map(|o| o.parse().ok())
        .collect();

    CorsLayer::new()
        .allow_origin(origins)
        .allow_methods(allowed_methods)
        .allow_headers(allowed_headers)
        .max_age(Duration::from_secs(3600))
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
        activated_at: Set(None),
        deleted_at: Set(None),
        created_at: Set(Utc::now().naive_utc()),
        updated_at: Set(Utc::now().naive_utc()),
    };

    admin.insert(db).await?;
    tracing::info!("Default admin account created (username: admin, status: pending_activation)");

    Ok(())
}

