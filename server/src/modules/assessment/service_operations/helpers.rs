pub fn get_difficulty_label(p: f64) -> String {
    match p {
        p if p >= 0.80 => "Very Easy".to_string(),
        p if p >= 0.60 => "Easy".to_string(),
        p if p >= 0.40 => "Average".to_string(),
        p if p >= 0.20 => "Difficult".to_string(),
        _ => "Very Difficult".to_string(),
    }
}

pub fn get_discrimination_label(d: f64) -> String {
    match d {
        d if d >= 0.40 => "Very Good".to_string(),
        d if d >= 0.30 => "Good".to_string(),
        d if d >= 0.20 => "Needs Revision".to_string(),
        _ => "Discard".to_string(),
    }
}

pub fn get_verdict(p: f64, d: f64) -> String {
    let p_in_range = p >= 0.20 && p <= 0.80;
    let d_good = d >= 0.30;

    if p_in_range && d_good {
        "retain".to_string()
    } else {
        let p_near = p >= 0.17 && p <= 0.83;
        let d_near = d >= 0.27;

        if p_near && d_near {
            "revise".to_string()
        } else {
            "discard".to_string()
        }
    }
}
