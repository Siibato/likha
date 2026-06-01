use uuid::Uuid;

/// Compute percentage and weighted score for a single component.
pub(crate) fn compute_component(
    items: &[&::entity::grade_items::Model],
    score_map: &std::collections::HashMap<Uuid, f64>,
    weight: f64,
) -> (f64, f64) {
    let mut sum_scores = 0.0;
    let mut sum_total = 0.0;

    for item in items {
        if let Some(&score) = score_map.get(&item.id) {
            sum_scores += score;
            sum_total += item.total_points;
        } else {
            sum_total += item.total_points;
        }
    }

    if sum_total <= 0.0 {
        return (0.0, 0.0);
    }

    let percentage = (sum_scores / sum_total) * 100.0;
    let weighted = percentage * (weight / 100.0);
    (percentage, weighted)
}
