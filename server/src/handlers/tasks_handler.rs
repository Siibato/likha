use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use std::sync::Arc;
use uuid::Uuid;

use crate::middleware::auth_middleware::AuthUser;
use crate::routes::tasks_routes::TasksState;
use crate::schema::common::success_response;
use crate::schema::tasks_schema::{TaskItemResponse, TaskListResponse};
use crate::utils::error::AppError;

pub async fn get_student_tasks(
    State(state): State<Arc<TasksState>>,
    auth_user: AuthUser,
    Path(class_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth_user.role != "student" {
        return AppError::Forbidden("Student access required".to_string()).into_response();
    }

    // Fetch published assignments with student submission data
    let assignments = match state
        .assignment_service
        .get_student_assignments(class_id, auth_user.user_id)
        .await
    {
        Ok(r) => r.assignments,
        Err(e) => return e.into_response(),
    };

    // Fetch published assessments with student submission data
    let assessments = match state
        .assessment_service
        .get_student_assessments(class_id, auth_user.user_id)
        .await
    {
        Ok(items) => items,
        Err(e) => return e.into_response(),
    };

    // Map both to unified TaskItemResponse
    let mut tasks: Vec<TaskItemResponse> = assignments
        .into_iter()
        .map(|a| TaskItemResponse {
            task_type: "assignment".to_string(),
            id: a.id,
            class_id,
            title: a.title,
            total_points: a.total_points,
            is_published: a.is_published,
            due_at: Some(a.due_at),
            submission_type: Some(a.submission_type),
            submission_status: a.submission_status,
            submission_id: a.submission_id,
            score: a.score,
            open_at: None,
            close_at: None,
            is_submitted: None,
            time_limit_minutes: None,
        })
        .collect();

    tasks.extend(
        assessments
            .into_iter()
            .map(|a| TaskItemResponse {
                task_type: "assessment".to_string(),
                id: a.id,
                class_id,
                title: a.title,
                total_points: a.total_points,
                is_published: true, // find_published_by_class_id guarantees this
                due_at: None,
                submission_type: None,
                submission_status: None,
                submission_id: None,
                score: None,
                open_at: Some(a.open_at),
                close_at: Some(a.close_at),
                is_submitted: a.is_submitted,
                time_limit_minutes: Some(a.time_limit_minutes),
            }),
    );

    // Sort: by due_at/close_at (both are ISO strings — lexicographic sort works)
    tasks.sort_by(|a, b| {
        let a_date = a
            .due_at
            .as_deref()
            .or(a.close_at.as_deref())
            .unwrap_or("");
        let b_date = b
            .due_at
            .as_deref()
            .or(b.close_at.as_deref())
            .unwrap_or("");
        a_date.cmp(b_date)
    });

    success_response(TaskListResponse { tasks }, StatusCode::OK).into_response()
}
