pub fn period_count(term_type: &str) -> usize {
    match term_type {
        "semester" => 2,
        "trimester" => 3,
        _ => 4, // "quarter" or default
    }
}
