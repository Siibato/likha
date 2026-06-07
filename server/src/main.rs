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

use server::modules::assessment::service::AssessmentService;
use server::modules::assignment::service::AssignmentService;
use server::modules::auth::service::AuthService;
use server::modules::class::service::ClassService;
use server::modules::learning_material::service::LearningMaterialService;
use server::modules::tos::service::TosService;
use server::modules::grading::service::GradeComputationService;
use server::modules::setup::service::SetupService;
use server::modules::entitlement::EntitlementService;
use server::modules::sync::service::{SyncPushService, SyncConflictService, SyncFullService, SyncDeltaService};
use server::utils::file_encryption::parse_key;
use server::modules::sync::{ManifestRepository, ProcessedOperationsRepository};
use server::cache::{RedisCache, CacheTtl};
use server::middleware::{RateLimitLayer, RateLimitStore};

#[tokio::main(flavor = "multi_thread", worker_threads = 16)]
async fn main() {
    dotenv().ok();

    tracing_subscriber::fmt()
        .with_target(false)
        .compact()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let config = server::config::ServerConfig::from_env();
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
                let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
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
                let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                run_migrations(&db).await.expect("Failed to run migrations");
                seed_admin(&db).await.expect("Failed to seed admin account");

                if args.iter().any(|arg| arg == "--with-seed") {
                    println!("Seeding manual testing world...");
                    server::seed::scenarios::manual::seed_manual_world(&db).await.expect("Manual seed failed");
                    println!("Manual seed complete.");
                }

                println!("Database reset complete");
                return;
            }
            "clear-invalid-attempts" => {
                let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                let repo = server::modules::auth::LoginAttemptRepository::new(db);
                repo.clear_all_attempts().await.expect("Failed to clear attempts");
                println!("All login attempt records cleared.");
                return;
            }
            "seed-e2e" => {
                println!("Seeding deterministic E2E world...");
                let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                server::seed::scenarios::e2e::seed_e2e_world(&db).await.expect("E2E seed failed");
                println!("E2E seed complete.");
                return;
            }
            "seed-manual" => {
                println!("Seeding manual testing world...");
                let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");
                server::seed::scenarios::manual::seed_manual_world(&db).await.expect("Manual seed failed");
                println!("Manual seed complete.");

                // Optional: --export-manifest <path>
                if let Some(flag_pos) = args.iter().position(|a| a == "--export-manifest") {
                    let manifest_path = args.get(flag_pos + 1)
                        .map(|s| s.as_str())
                        .unwrap_or("../load-tests/seed-manifest.json");

                    let ctx = server::seed::tools::SeedContext::new();
                    let users = server::seed::fixtures::manual::manual_users(&ctx);
                    let classes = server::seed::fixtures::manual::manual_classes(&ctx);
                    let assessments = server::seed::fixtures::manual::manual_assessments(&ctx);
                    let assignments = server::seed::fixtures::manual::manual_assignments(&ctx);

                    let manifest = server::seed::manifest::build_manifest(
                        &users, &classes, &assessments, &assignments,
                    );
                    server::seed::manifest::export_manifest(&manifest, manifest_path)
                        .expect("Failed to export seed manifest");
                }

                return;
            }
            "deseed" => {
                use sea_orm::ConnectionTrait;
                println!("Clearing all seeded data and re-initializing...");
                let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
                    .await
                    .expect("Failed to connect to database");

                // Get all table names to clear (excluding migrations)
                let tables = vec![
                    "users", "classes", "enrollments", "assessments", "assessment_questions",
                    "question_choices", "answer_keys", "tos_competencies", "table_of_specifications",
                    "assignments", "learning_materials", "assessment_submissions", "submission_answers",
                    "submission_answer_items", "assignment_submissions", "grade_record", "grade_items",
                    "grade_scores", "period_grades", "activity_logs", "advisory_class_students",
                    "sync_manifest", "sync_processed_operations",
                ];

                for table in tables {
                    let sql = format!("DELETE FROM {}", table);
                    if let Err(e) = db.execute_unprepared(&sql).await {
                        eprintln!("Warning: Failed to clear table {}: {}", table, e);
                    }
                }

                // Reset admin account
                seed_admin(&db).await.expect("Failed to seed admin account");
                println!("Deseed complete. All data cleared, admin account reset.");
                return;
            }
            other => {
                eprintln!("Unknown command: {}", other);
                eprintln!("Available commands:");
                eprintln!("  create-db               Create the database and run migrations");
                eprintln!("  delete-db               Delete the database file");
                eprintln!("  reset-db                Delete and recreate the database");
                eprintln!("  reset-db --with-seed    Reset and seed manual test data");
                eprintln!("  clear-invalid-attempts  Clear all login attempt records");
                eprintln!("  seed-e2e                Seed deterministic E2E world data");
                eprintln!("  seed-manual             Seed manual testing world data");
                eprintln!("  seed-manual --export-manifest <path>  Seed and export manifest JSON (default: ../load-tests/seed-manifest.json)");
                eprintln!("  deseed                  Clear all seeded data and reset admin");
                std::process::exit(1);
            }
        }
    }

    tracing::info!("Starting Offline LMS Server");
    tracing::info!("Host: {}", config.host);
    tracing::info!("Port: {}", config.port);

    // Connect to database
    let db = server::db::establish_connection(&config.database_url, &config.db_encryption_key)
        .await
        .expect("Failed to connect to database");

    // Run migrations
    run_migrations(&db)
        .await
        .expect("Failed to run migrations");

    // Seed default admin account
    seed_admin(&db).await.expect("Failed to seed admin account");

    // Initialize services
    let auth_service = Arc::new(server::modules::auth::service::AuthService::new(
        db.clone(),
        config.jwt_secret.clone(),
        config.jwt_expiration,
    ));

    let admin_service = Arc::new(server::modules::admin::service::AdminService::new(db.clone()));

    // Initialize Redis cache
    let cache_ttl = CacheTtl {
        list_seconds: config.cache_ttl_list_seconds,
        detail_seconds: config.cache_ttl_detail_seconds,
        static_seconds: config.cache_ttl_static_seconds,
    };
    let redis_cache = RedisCache::new(&config.redis_url, config.cache_enabled, cache_ttl).await;

    let class_service = Arc::new(ClassService::new(db.clone()).with_cache(redis_cache.clone()));

    let assessment_service = Arc::new(AssessmentService::new(db.clone()).with_cache(redis_cache.clone()));

    // Parse file encryption key from hex string
    let file_encryption_key = parse_key(&config.file_encryption_key)
        .expect("Invalid FILE_ENCRYPTION_KEY format");

    let assignment_service = Arc::new(AssignmentService::new(db.clone()).with_cache(redis_cache.clone()));
    let material_service = Arc::new(LearningMaterialService::new(
        db.clone(),
        config.file_storage_path.clone(),
        file_encryption_key,
    ));

    // Initialize new offline-first sync services
    let _entitlement_repo = server::modules::entitlement::repository::EntitlementRepository::new(db.clone());
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
        admin_service.clone(),
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
        admin_service,
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
    config: &server::config::ServerConfig,
    auth_service: Arc<AuthService>,
    admin_service: Arc<server::modules::admin::service::AdminService>,
    class_service: Arc<server::modules::class::service::ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    grade_computation_service: Arc<GradeComputationService>,
    tos_service: Arc<TosService>,
    setup_service: Arc<server::modules::setup::service::SetupService>,
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
    sync_full_service: Arc<SyncFullService>,
    sync_delta_service: Arc<SyncDeltaService>,
) -> Router {
    let rate_limit_store = Arc::new(RateLimitStore::new());
    let jwt_secret = std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");

    let api = Router::new()
        .merge(server::modules::health::routes::routes())
        .merge(server::modules::auth::routes::routes(auth_service.clone()))
        .merge(server::modules::admin::routes::routes(admin_service))
        .merge(server::modules::class::routes::routes(class_service))
        .merge(server::modules::assessment::routes::routes(assessment_service.clone()))
        .merge(server::modules::assignment::routes::routes(assignment_service.clone()))
        .merge(server::modules::learning_material::routes::routes(material_service))
        .merge(server::modules::grading::routes::routes(grade_computation_service))
        .merge(server::modules::tos::routes::routes(tos_service))
        .merge(server::modules::setup::routes::routes(setup_service))
        .merge(server::modules::tasks::routes::routes(assignment_service, assessment_service))
        .merge(server::modules::sync::routes::routes(
            sync_push_service,
            sync_conflict_service,
            sync_full_service,
            sync_delta_service,
        ))
        .layer(RateLimitLayer::new(rate_limit_store, jwt_secret));

    Router::new().nest("/api/v1", api)
        .layer(RequestBodyLimitLayer::new(config.max_body_size_bytes as usize))
        .layer(TimeoutLayer::with_status_code(axum::http::StatusCode::REQUEST_TIMEOUT, Duration::from_secs(60)))
        .layer(build_cors_layer(config))
        .layer(axum::middleware::from_fn(server::middleware::add_security_headers))
        .layer(server::middleware::logging_middleware())
}

fn build_cors_layer(config: &server::config::ServerConfig) -> CorsLayer {
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

