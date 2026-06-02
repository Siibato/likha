pub mod auth_routes;
pub mod health_routes;
pub mod tasks_routes;

use axum::Router;
use std::sync::Arc;

use crate::middleware::{RateLimitLayer, RateLimitStore};
use crate::modules::assessment::service::AssessmentService;
use crate::modules::assignment::service::AssignmentService;
use crate::modules::auth::service::AuthService;
use crate::modules::admin::service::AdminService;
use crate::modules::class::routes as new_class_routes;
use crate::modules::auth::routes as new_auth_routes;
use crate::modules::admin::routes as new_admin_routes;
use crate::modules::tos::routes as new_tos_routes;
use crate::modules::learning_material::routes as new_learning_material_routes;
use crate::modules::learning_material::service::LearningMaterialService;
use crate::modules::tos::service::TosService;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::sync::service::{SyncPushService, SyncConflictService, SyncFullService, SyncDeltaService};

pub fn api_routes(
    auth_service: Arc<AuthService>,
    admin_service: Arc<AdminService>,
    class_service: Arc<crate::modules::class::service::ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    grade_computation_service: Arc<GradeComputationService>,
    tos_service: Arc<TosService>,
    setup_service: Arc<crate::modules::setup::service::SetupService>,
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
    sync_full_service: Arc<SyncFullService>,
    sync_delta_service: Arc<SyncDeltaService>,
) -> Router {
    let rate_limit_store = Arc::new(RateLimitStore::new());
    let jwt_secret = std::env::var("JWT_SECRET").expect("JWT_SECRET must be set");

    Router::new()
        .merge(health_routes::routes())
        .merge(new_auth_routes::routes(auth_service.clone()))
        .merge(new_admin_routes::routes(admin_service))
        .merge(new_class_routes::routes(class_service))
        .merge(crate::modules::assessment::routes::routes(assessment_service.clone()))
        .merge(crate::modules::assignment::routes::routes(assignment_service.clone()))
        .merge(new_learning_material_routes::routes(material_service))
        .merge(crate::modules::grading::routes::routes(grade_computation_service))
        .merge(new_tos_routes::routes(tos_service))
        .merge(crate::modules::setup::routes::routes(setup_service))
        .merge(tasks_routes::routes(assignment_service, assessment_service))
        .merge(crate::modules::sync::routes::routes(
            sync_push_service,
            sync_conflict_service,
            sync_full_service,
            sync_delta_service,
        ))
        .layer(RateLimitLayer::new(rate_limit_store, jwt_secret))
}
