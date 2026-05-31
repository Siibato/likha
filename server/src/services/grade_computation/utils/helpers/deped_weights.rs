/// DepEd weight presets from DepEd Order No. 8, s. 2015

#[derive(Debug, Clone)]
pub struct WeightPreset {
    pub ww: f64,
    pub pt: f64,
    pub qa: f64,
}

/// Get DepEd standard weight preset for a given subject group.
pub fn get_preset(subject_group: &str) -> Option<WeightPreset> {
    match subject_group {
        "language" => Some(WeightPreset { ww: 30.0, pt: 50.0, qa: 20.0 }),
        "ap_esp" => Some(WeightPreset { ww: 30.0, pt: 50.0, qa: 20.0 }),
        "math_sci" => Some(WeightPreset { ww: 40.0, pt: 40.0, qa: 20.0 }),
        "mapeh_tle" => Some(WeightPreset { ww: 20.0, pt: 60.0, qa: 20.0 }),
        "shs_core" => Some(WeightPreset { ww: 25.0, pt: 50.0, qa: 25.0 }),
        "shs_academic" => Some(WeightPreset { ww: 25.0, pt: 45.0, qa: 30.0 }),
        "shs_tvl" => Some(WeightPreset { ww: 25.0, pt: 45.0, qa: 30.0 }),
        "shs_immersion" => Some(WeightPreset { ww: 35.0, pt: 40.0, qa: 25.0 }),
        _ => None,
    }
}

/// Get all available presets with display labels.
pub fn get_all_presets() -> Vec<(&'static str, &'static str, WeightPreset)> {
    vec![
        ("language", "Languages (Mother Tongue, Filipino, English)", WeightPreset { ww: 30.0, pt: 50.0, qa: 20.0 }),
        ("ap_esp", "AP, EsP", WeightPreset { ww: 30.0, pt: 50.0, qa: 20.0 }),
        ("math_sci", "Science, Math", WeightPreset { ww: 40.0, pt: 40.0, qa: 20.0 }),
        ("mapeh_tle", "MAPEH, EPP/TLE", WeightPreset { ww: 20.0, pt: 60.0, qa: 20.0 }),
        ("shs_core", "SHS Core Subjects", WeightPreset { ww: 25.0, pt: 50.0, qa: 25.0 }),
        ("shs_academic", "SHS Academic Track (ABM, HUMSS, STEM, GAS)", WeightPreset { ww: 25.0, pt: 45.0, qa: 30.0 }),
        ("shs_tvl", "SHS TVL / Sports / Arts and Design Track", WeightPreset { ww: 25.0, pt: 45.0, qa: 30.0 }),
        ("shs_immersion", "Work Immersion, Research, Business Enterprise, Exhibit/Performance", WeightPreset { ww: 35.0, pt: 40.0, qa: 25.0 }),
    ]
}

/// Apply DepEd transmutation formula to an initial grade.
///
/// - If initial >= 100: returns 100
/// - If initial >= 60: returns floor(75 + (initial - 60) / 1.6)
/// - If initial < 60: returns floor(60 + initial / 4)
pub fn transmute_grade(initial_grade: f64) -> i32 {
    if initial_grade >= 100.0 {
        return 100;
    }
    if initial_grade >= 60.0 {
        return (75.0 + (initial_grade - 60.0) / 1.6).floor() as i32;
    }
    (60.0 + initial_grade / 4.0).floor() as i32
}

/// Get grade descriptor from transmuted grade.
pub fn get_descriptor(transmuted: i32) -> &'static str {
    match transmuted {
        90..=100 => "Outstanding",
        85..=89 => "Very Satisfactory",
        80..=84 => "Satisfactory",
        75..=79 => "Fairly Satisfactory",
        _ => "Did Not Meet Expectations",
    }
}

/// Get short descriptor code.
pub fn get_descriptor_code(transmuted: i32) -> &'static str {
    match transmuted {
        90..=100 => "O",
        85..=89 => "VS",
        80..=84 => "S",
        75..=79 => "FS",
        _ => "DNME",
    }
}
