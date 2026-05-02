use axum::Router;
use sea_orm::DatabaseConnection;
use std::sync::Arc;
use std::time::Duration;
use axum::http::header::{ACCEPT, AUTHORIZATION, CONTENT_TYPE};
use tower_http::cors::{Any, CorsLayer};
use tower_http::timeout::TimeoutLayer;

use crate::db::repositories::{
    manifest_repository::ManifestRepository,
    processed_operations_repository::ProcessedOperationsRepository,
};
use crate::routes::api_routes;
use crate::services::{
    assessment::AssessmentService,
    assignment::AssignmentService,
    auth::AuthService,
    class::ClassService,
    entitlement::EntitlementService,
    grade_computation::GradeComputationService,
    learning_material::LearningMaterialService,
    setup_service::SetupService,
    sync_conflict_service::SyncConflictService,
    sync_delta::SyncDeltaService,
    sync_full::SyncFullService,
    sync_push::SyncPushService,
    tos::TosService,
};

/// The auth middleware reads JWT_SECRET from the env, falling back to this constant.
/// We match it here so tokens generated in tests are accepted by the middleware.
pub const TEST_JWT_SECRET: &str = "default_secret";
pub const TEST_FILE_STORAGE: &str = "/tmp/likha_test_files";

pub async fn build_test_app(db: DatabaseConnection) -> Router {
    // Ensure JWT_SECRET is set so auth middleware does not panic.
    std::env::set_var("JWT_SECRET", TEST_JWT_SECRET);
    let auth_service = Arc::new(AuthService::new(
        db.clone(),
        TEST_JWT_SECRET.to_string(),
        3600,
    ));
    let class_service = Arc::new(ClassService::new(db.clone()));
    let assessment_service = Arc::new(AssessmentService::new(db.clone()));
    let assignment_service = Arc::new(AssignmentService::new(
        db.clone(),
        TEST_FILE_STORAGE.to_string(),
    ));
    let material_service = Arc::new(LearningMaterialService::new(
        db.clone(),
        TEST_FILE_STORAGE.to_string(),
    ));
    let grade_computation_service = Arc::new(GradeComputationService::new(db.clone()));
    let tos_service = Arc::new(TosService::new(db.clone()));
    let setup_service =
        Arc::new(SetupService::new(db.clone(), "TEST-CODE".to_string()).await);
    let entitlement_service = Arc::new(EntitlementService::new(db.clone()));
    let manifest_repo = ManifestRepository::new(db.clone());
    let processed_ops_repo = Arc::new(ProcessedOperationsRepository::new(db.clone()));

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
        entitlement_service,
        manifest_repo,
        db,
    ));

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers([AUTHORIZATION, CONTENT_TYPE, ACCEPT]);

    Router::new()
        .nest(
            "/api/v1",
            api_routes(
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
        .layer(TimeoutLayer::with_status_code(
            axum::http::StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(30),
        ))
        .layer(cors)
}
