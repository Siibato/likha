pub mod assessment_routes;
pub mod assignment_routes;
pub mod auth_routes;
pub mod class_routes;
pub mod health_routes;
pub mod learning_material_routes;
pub mod sync_routes_new;

use axum::Router;
use std::sync::Arc;

use crate::services::assessment_service::AssessmentService;
use crate::services::assignment_service::AssignmentService;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;
use crate::services::learning_material_service::LearningMaterialService;
use crate::services::sync_manifest_service::SyncManifestService;
use crate::services::sync_fetch_service::SyncFetchService;
use crate::services::sync_push_service::SyncPushService;
use crate::services::sync_conflict_service::SyncConflictService;

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
        ))
}
