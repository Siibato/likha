pub fn term_count(term_type: &str) -> usize {
    match term_type {
        "semester" => 2,
        "trimester" => 3,
        _ => 3, // "term" or default
    }
}
