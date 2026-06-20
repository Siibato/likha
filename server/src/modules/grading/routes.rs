use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;

use crate::modules::grading::handler;
use crate::modules::grading::service::GradeComputationService;

pub fn routes(grade_service: Arc<GradeComputationService>) -> Router {
    Router::new()
        // Config
        .route(
            "/classes/{class_id}/grading-config",
            get(handler::get_grading_config),
        )
        .route(
            "/classes/{class_id}/grading-config",
            put(handler::update_grading_config),
        )
        .route(
            "/classes/{class_id}/grading-config/setup",
            post(handler::setup_grading_config),
        )
        // Grade Items
        .route(
            "/classes/{class_id}/grade-items",
            get(handler::get_grade_items),
        )
        .route(
            "/classes/{class_id}/grade-items",
            post(handler::create_grade_item),
        )
        .route(
            "/classes/{class_id}/grade-items/batch",
            post(handler::create_grade_items_batch),
        )
        .route(
            "/grade-items/{id}",
            put(handler::update_grade_item),
        )
        .route(
            "/grade-items/{id}",
            delete(handler::delete_grade_item),
        )
        // Scores
        .route(
            "/grade-items/{id}/scores",
            get(handler::get_item_scores),
        )
        .route(
            "/grade-items/{id}/scores",
            put(handler::update_item_scores),
        )
        .route(
            "/grade-scores/batch",
            put(handler::update_scores_batch),
        )
        .route(
            "/grade-scores/{id}/override",
            put(handler::override_score),
        )
        .route(
            "/grade-scores/{id}/override",
            delete(handler::delete_score_override),
        )
        // Computed Grades
        .route(
            "/classes/{class_id}/grades",
            get(handler::get_grades),
        )
        .route(
            "/classes/{class_id}/grades/compute",
            post(handler::compute_grades),
        )
        .route(
            "/classes/{class_id}/grades/final",
            get(handler::get_final_grades),
        )
        .route(
            "/classes/{class_id}/grades/summary",
            get(handler::get_grade_summary),
        )
        .route(
            "/classes/{class_id}/grade-data",
            get(handler::get_all_grade_data),
        )
        // Student
        .route(
            "/classes/{class_id}/my-grades",
            get(handler::get_my_grades),
        )
        .route(
            "/classes/{class_id}/my-grades/{term_number}",
            get(handler::get_my_term_grades),
        )
        // Utility
        .route(
            "/grading/deped-presets",
            get(handler::get_deped_presets),
        )
        // General Average (GSA)
        .route(
            "/classes/{class_id}/grades/general-average",
            get(handler::get_general_averages),
        )
        // SF9/SF10
        .route(
            "/classes/{class_id}/sf9/{student_id}",
            get(handler::get_sf9),
        )
        .route(
            "/classes/{class_id}/sf10/{student_id}",
            get(handler::get_sf10),
        )
        .with_state(grade_service)
}
