pub mod assessment_routes;
pub mod assignment_routes;
pub mod auth_routes;
pub mod class_routes;
pub mod health_routes;
pub mod learning_material_routes;
pub mod sync_routes_new;
pub mod tasks_routes;

use axum::Router;
use std::sync::Arc;

use crate::services::assessment::AssessmentService;
use crate::services::assignment::AssignmentService;
use crate::services::auth::AuthService;
use crate::services::class::ClassService;
use crate::services::learning_material::LearningMaterialService;
use crate::services::sync_push::SyncPushService;
use crate::services::sync_conflict_service::SyncConflictService;
use crate::services::sync_full::SyncFullService;
use crate::services::sync_delta::SyncDeltaService;

pub fn api_routes(
    auth_service: Arc<AuthService>,
    class_service: Arc<ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
    sync_push_service: Arc<SyncPushService>,
    sync_conflict_service: Arc<SyncConflictService>,
    sync_full_service: Arc<SyncFullService>,
    sync_delta_service: Arc<SyncDeltaService>,
) -> Router {
    Router::new()
        .merge(health_routes::routes())
        .merge(auth_routes::routes(auth_service.clone()))
        .merge(class_routes::routes(class_service, auth_service))
        .merge(assessment_routes::routes(assessment_service.clone()))
        .merge(assignment_routes::routes(assignment_service.clone()))
        .merge(learning_material_routes::routes(material_service))
        .merge(tasks_routes::routes(assignment_service, assessment_service))
        .merge(sync_routes_new::routes(
            sync_push_service,
            sync_conflict_service,
            sync_full_service,
            sync_delta_service,
        ))
}
