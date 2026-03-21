use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::handlers::grading_handler;
use crate::services::grade_computation::GradeComputationService;

pub fn routes(grade_service: Arc<GradeComputationService>) -> Router {
    Router::new()
        // Config
        .route(
            "/classes/{class_id}/grading-config",
            get(grading_handler::get_grading_config),
        )
        .route(
            "/classes/{class_id}/grading-config",
            put(grading_handler::update_grading_config),
        )
        .route(
            "/classes/{class_id}/grading-config/setup",
            post(grading_handler::setup_grading_config),
        )
        // Grade Items
        .route(
            "/classes/{class_id}/grade-items",
            get(grading_handler::get_grade_items),
        )
        .route(
            "/classes/{class_id}/grade-items",
            post(grading_handler::create_grade_item),
        )
        .route(
            "/grade-items/{id}",
            put(grading_handler::update_grade_item),
        )
        .route(
            "/grade-items/{id}",
            delete(grading_handler::delete_grade_item),
        )
        // Scores
        .route(
            "/grade-items/{id}/scores",
            get(grading_handler::get_item_scores),
        )
        .route(
            "/grade-items/{id}/scores",
            put(grading_handler::update_item_scores),
        )
        .route(
            "/grade-scores/{id}/override",
            put(grading_handler::override_score),
        )
        .route(
            "/grade-scores/{id}/override",
            delete(grading_handler::delete_score_override),
        )
        // Computed Grades
        .route(
            "/classes/{class_id}/grades",
            get(grading_handler::get_grades),
        )
        .route(
            "/classes/{class_id}/grades/compute",
            post(grading_handler::compute_grades),
        )
        .route(
            "/classes/{class_id}/grades/final",
            get(grading_handler::get_final_grades),
        )
        .route(
            "/classes/{class_id}/grades/summary",
            get(grading_handler::get_grade_summary),
        )
        // Student
        .route(
            "/classes/{class_id}/my-grades",
            get(grading_handler::get_my_grades),
        )
        .route(
            "/classes/{class_id}/my-grades/{quarter}",
            get(grading_handler::get_my_quarter_grades),
        )
        // Utility
        .route(
            "/grading/deped-presets",
            get(grading_handler::get_deped_presets),
        )
        .with_state(grade_service)
}
