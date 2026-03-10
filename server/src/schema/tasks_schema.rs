use serde::Serialize;
use uuid::Uuid;

#[derive(Debug, Serialize)]
pub struct TaskItemResponse {
    pub task_type: String,               // "assignment" or "assessment"
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub total_points: i32,
    pub is_published: bool,
    // Assignment-specific
    pub due_at: Option<String>,
    pub submission_type: Option<String>,
    pub submission_status: Option<String>,
    pub submission_id: Option<Uuid>,
    pub score: Option<i32>,
    // Assessment-specific
    pub open_at: Option<String>,
    pub close_at: Option<String>,
    pub is_submitted: Option<bool>,
    pub time_limit_minutes: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct TaskListResponse {
    pub tasks: Vec<TaskItemResponse>,
}

// Internal struct for assessment data
#[derive(Debug)]
pub struct StudentAssessmentListItem {
    pub id: Uuid,
    pub title: String,
    pub total_points: i32,
    pub open_at: String,
    pub close_at: String,
    pub time_limit_minutes: i32,
    pub is_submitted: Option<bool>,
}
