use crate::modules::grading::repository::GradeComputationRepository;
use crate::utils::AppResult;
use uuid::Uuid;

/// Auto-create a linked grade item when an assessment/assignment is published with grading metadata.
/// Idempotent — if a linked item already exists, does nothing.
pub async fn create_linked_grade_item(
    repo: &GradeComputationRepository,
    source_type: &str,
    source_id: Uuid,
    class_id: Uuid,
    title: &str,
    component: &str,
    term_number: i32,
    total_points: f64,
) -> AppResult<()> {
    if repo
        .find_by_source(source_type, &source_id.to_string())
        .await?
        .is_some()
    {
        return Ok(());
    }

    let existing = repo
        .get_items_by_component(class_id, term_number, component)
        .await?;
    let order_index = existing.len() as i32;

    repo.create_item(
        class_id,
        title.to_string(),
        component.to_string(),
        Some(term_number),
        total_points,
        source_type.to_string(),
        Some(source_id.to_string()),
        order_index,
        None,
    )
    .await?;

    Ok(())
}

/// Auto-populate a grade score when a submission is graded.
/// Only updates the `score` field with `is_auto_populated=true`.
/// Does NOT overwrite if `override_score` is already set (handled by SQL UPSERT).
pub async fn auto_populate_score(
    repo: &GradeComputationRepository,
    source_type: &str,
    source_id: Uuid,
    student_id: Uuid,
    score: f64,
) -> AppResult<Option<uuid::Uuid>> {
    let grade_item = repo
        .find_by_source(source_type, &source_id.to_string())
        .await?;
    if let Some(item) = grade_item {
        repo.upsert_score(item.id, student_id, Some(score), true)
            .await?;
        Ok(Some(item.id))
    } else {
        Ok(None)
    }
}
