pub mod assessment_routes;
pub mod assignment_routes;
pub mod auth_routes;
pub mod class_routes;
pub mod health_routes;
pub mod learning_material_routes;

use axum::Router;
use std::sync::Arc;

use crate::services::assessment_service::AssessmentService;
use crate::services::assignment_service::AssignmentService;
use crate::services::auth_service::AuthService;
use crate::services::class_service::ClassService;
use crate::services::learning_material_service::LearningMaterialService;

pub fn api_routes(
    auth_service: Arc<AuthService>,
    class_service: Arc<ClassService>,
    assessment_service: Arc<AssessmentService>,
    assignment_service: Arc<AssignmentService>,
    material_service: Arc<LearningMaterialService>,
) -> Router {
    Router::new()
        .merge(health_routes::routes())
        .merge(auth_routes::routes(auth_service.clone()))
        .merge(class_routes::routes(class_service, auth_service))
        .merge(assessment_routes::routes(assessment_service))
        .merge(assignment_routes::routes(assignment_service))
        .merge(learning_material_routes::routes(material_service))
}
