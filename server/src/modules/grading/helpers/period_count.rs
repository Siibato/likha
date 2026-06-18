pub fn period_count(grading_period_type: &str) -> usize {
    match grading_period_type {
        "semester" => 2,
        "trimester" => 3,
        _ => 4, // "quarter" or default
    }
}
