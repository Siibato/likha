pub mod assessment_routes;
pub mod assignment_routes;
pub mod auth_routes;
pub mod class_routes;
pub mod health_routes;
pub mod learning_material_routes;
pub mod sync_routes_new;

use axum::Router;
use std::sync::Arc;

use crate::services::assessment::AssessmentService;
use crate::services::assignment::AssignmentService;
use crate::services::auth::AuthService;
use crate::services::class::ClassService;
use crate::services::learning_material::LearningMaterialService;
use crate::services::sync_manifest_service::SyncManifestService;
use crate::services::sync_fetch_service::SyncFetchService;
use crate::services::sync_push_service::SyncPushService;
use crate::services::sync_conflict_service::SyncConflictService;
use crate::services::sync_full_service::SyncFullService;
use crate::services::sync_delta_service::SyncDeltaService;

pub fn api_routes(
    auth_service: Arc<AuthService>,
    class_service: Arc<ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    sync_manifest_service: Arc<SyncManifestService>,
    sync_fetch_service: Arc<SyncFetchService>,
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
    sync_full_service: Arc<SyncFullService>,
    sync_delta_service: Arc<SyncDeltaService>,
) -> Router {
    Router::new()
        .merge(health_routes::routes())
        .merge(auth_routes::routes(auth_service.clone()))
        .merge(class_routes::routes(class_service, auth_service))
        .merge(assessment_routes::routes(assessment_service))
        .merge(assignment_routes::routes(assignment_service))
        .merge(learning_material_routes::routes(material_service))
        .merge(sync_routes_new::routes(
            sync_manifest_service,
            sync_fetch_service,
            sync_push_service,
            sync_conflict_service,
            sync_full_service,
            sync_delta_service,
        ))
}
