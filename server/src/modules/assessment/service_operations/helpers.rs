pub fn get_difficulty_label(p: f64) -> String {
    match p {
        p if p >= 0.86 => "Very Easy".to_string(),
        p if p >= 0.71 => "Easy".to_string(),
        p if p >= 0.30 => "Moderate".to_string(),
        p if p >= 0.15 => "Difficult".to_string(),
        _ => "Very Difficult".to_string(),
    }
}

pub fn get_discrimination_label(d: f64) -> String {
    match d {
        d if d >= 0.40 => "Very Good".to_string(),
        d if d >= 0.30 => "Reasonably Good".to_string(),
        d if d >= 0.20 => "Marginal".to_string(),
        _ => "Poor".to_string(),
    }
}

pub fn get_verdict(p: f64, d: f64) -> String {
    let d_tier: u8 = if d >= 0.40 { 3 } else if d >= 0.30 { 2 } else if d >= 0.20 { 1 } else { 0 };
    let p_tier: u8 = if p >= 0.86 { 4 } else if p >= 0.71 { 3 } else if p >= 0.30 { 0 } else if p >= 0.15 { 2 } else { 4 };

    match (p_tier, d_tier) {
        (0, 3) | (0, 2) => "retain",
        (0, 1) | (0, 0) => "revise",
        (3, 3) => "retain",
        (3, 2) | (3, 1) | (3, 0) => "revise",
        (2, 3) => "retain",
        (2, 2) | (2, 1) | (2, 0) => "revise",
        (4, _) => "discard",
        _ => "discard",
    }.to_string()
}
