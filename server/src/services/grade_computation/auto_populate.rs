use uuid::Uuid;
use sea_orm::DatabaseConnection;
use crate::utils::AppResult;
use crate::db::repositories::grade_computation_repository::GradeComputationRepository;

/// Auto-create a linked grade item when an assessment/assignment is published with grading metadata.
/// Idempotent — if a linked item already exists, does nothing.
pub async fn create_linked_grade_item(
    db: &DatabaseConnection,
    source_type: &str,
    source_id: Uuid,
    class_id: Uuid,
    title: &str,
    component: &str,
    quarter: i32,
    total_points: f64,
) -> AppResult<()> {
    let repo = GradeComputationRepository::new(db.clone());

    // Idempotency check
    if repo.find_by_source(source_type, &source_id.to_string()).await?.is_some() {
        return Ok(()); // Already exists
    }

    // Determine order_index from existing items count
    let existing = repo.get_items_by_component(class_id, quarter, component).await?;
    let order_index = existing.len() as i32;

    repo.create_item(
        class_id,
        title.to_string(),
        component.to_string(),
        Some(quarter),
        total_points,
        source_type.to_string(),
        Some(source_id.to_string()),
        order_index,
    ).await?;

    Ok(())
}

/// Auto-populate a grade score when a submission is graded.
/// Only updates the `score` field with `is_auto_populated=true`.
/// Does NOT overwrite if `override_score` is already set (handled by SQL UPSERT).
pub async fn auto_populate_score(
    db: &DatabaseConnection,
    source_type: &str,
    source_id: Uuid,
    student_id: Uuid,
    score: f64,
) -> AppResult<()> {
    let repo = GradeComputationRepository::new(db.clone());

    let grade_item = repo.find_by_source(source_type, &source_id.to_string()).await?;
    if let Some(item) = grade_item {
        repo.upsert_score(item.id, student_id, Some(score), true).await?;
    }
    // If no linked grade item exists, silently skip (teacher hasn't set up grading for this item)

    Ok(())
}
