/// DepEd weight presets from DepEd Order No. 8, s. 2015 and DepEd Order No. 015, s. 2026

#[derive(Debug, Clone)]
pub struct WeightPreset {
    pub ww: f64,
    pub pt: f64,
    pub qa: f64,
}

/// Get DepEd standard weight preset for a given subject group.
pub fn get_preset(subject_group: &str) -> Option<WeightPreset> {
    match subject_group {
        // ── JHS: DepEd Order No. 8, s. 2015 ──
        "language" => Some(WeightPreset {
            ww: 30.0,
            pt: 50.0,
            qa: 20.0,
        }),
        "ap_esp" => Some(WeightPreset {
            ww: 30.0,
            pt: 50.0,
            qa: 20.0,
        }),
        "math_sci" => Some(WeightPreset {
            ww: 40.0,
            pt: 40.0,
            qa: 20.0,
        }),
        "mapeh_tle" => Some(WeightPreset {
            ww: 20.0,
            pt: 60.0,
            qa: 20.0,
        }),
        // ── SHS: DepEd Order No. 8, s. 2015 ──
        "shs_core" => Some(WeightPreset {
            ww: 25.0,
            pt: 50.0,
            qa: 25.0,
        }),
        "shs_academic" => Some(WeightPreset {
            ww: 25.0,
            pt: 45.0,
            qa: 30.0,
        }),
        "shs_tvl" => Some(WeightPreset {
            ww: 35.0,
            pt: 40.0,
            qa: 25.0,
        }),
        "shs_immersion" => Some(WeightPreset {
            ww: 20.0,
            pt: 60.0,
            qa: 20.0,
        }),
        // ── JHS: DepEd Order No. 015, s. 2026 ──
        "jhs_academic_do015" => Some(WeightPreset {
            ww: 20.0,
            pt: 50.0,
            qa: 30.0,
        }),
        // ── SHS: DepEd Order No. 015, s. 2026 ──
        "shs_core_do015" => Some(WeightPreset {
            ww: 20.0,
            pt: 50.0,
            qa: 30.0,
        }),
        "shs_field_exposure" => Some(WeightPreset {
            ww: 15.0,
            pt: 70.0,
            qa: 15.0,
        }),
        "shs_arts_sports_health" => Some(WeightPreset {
            ww: 20.0,
            pt: 60.0,
            qa: 20.0,
        }),
        "shs_research_design" => Some(WeightPreset {
            ww: 40.0,
            pt: 60.0,
            qa: 0.0,
        }),
        "shs_techpro" => Some(WeightPreset {
            ww: 15.0,
            pt: 65.0,
            qa: 20.0,
        }),
        "shs_work_immersion_do015" => Some(WeightPreset {
            ww: 20.0,
            pt: 80.0,
            qa: 0.0,
        }),
        _ => None,
    }
}

/// Get all available presets with display labels.
pub fn get_all_presets() -> Vec<(&'static str, &'static str, WeightPreset)> {
    vec![
        // ── JHS: DepEd Order No. 8, s. 2015 ──
        (
            "language",
            "Languages (Mother Tongue, Filipino, English) — DO 8 s 2015",
            WeightPreset {
                ww: 30.0,
                pt: 50.0,
                qa: 20.0,
            },
        ),
        (
            "ap_esp",
            "AP, EsP — DO 8 s 2015",
            WeightPreset {
                ww: 30.0,
                pt: 50.0,
                qa: 20.0,
            },
        ),
        (
            "math_sci",
            "Science, Math — DO 8 s 2015",
            WeightPreset {
                ww: 40.0,
                pt: 40.0,
                qa: 20.0,
            },
        ),
        (
            "mapeh_tle",
            "MAPEH, EPP/TLE — DO 8 s 2015",
            WeightPreset {
                ww: 20.0,
                pt: 60.0,
                qa: 20.0,
            },
        ),
        // ── SHS: DepEd Order No. 8, s. 2015 ──
        (
            "shs_core",
            "SHS Core Subjects — DO 8 s 2015",
            WeightPreset {
                ww: 25.0,
                pt: 50.0,
                qa: 25.0,
            },
        ),
        (
            "shs_academic",
            "SHS Academic Track (ABM, HUMSS, STEM, GAS) — DO 8 s 2015",
            WeightPreset {
                ww: 25.0,
                pt: 45.0,
                qa: 30.0,
            },
        ),
        (
            "shs_tvl",
            "SHS TVL / Sports / Arts and Design Track — DO 8 s 2015",
            WeightPreset {
                ww: 35.0,
                pt: 40.0,
                qa: 25.0,
            },
        ),
        (
            "shs_immersion",
            "Work Immersion, Research, Business Enterprise — DO 8 s 2015",
            WeightPreset {
                ww: 20.0,
                pt: 60.0,
                qa: 20.0,
            },
        ),
        // ── JHS: DepEd Order No. 015, s. 2026 ──
        (
            "jhs_academic_do015",
            "Academic Subjects (Eng, Fil, Math, Sci, AP, GMRC/VE) — DO 015 s 2026",
            WeightPreset {
                ww: 20.0,
                pt: 50.0,
                qa: 30.0,
            },
        ),
        // ── SHS: DepEd Order No. 015, s. 2026 ──
        (
            "shs_core_do015",
            "SHS Core & Academic Electives — DO 015 s 2026",
            WeightPreset {
                ww: 20.0,
                pt: 50.0,
                qa: 30.0,
            },
        ),
        (
            "shs_field_exposure",
            "Field Exposure / Arts Apprenticeship / Creative Production — DO 015 s 2026",
            WeightPreset {
                ww: 15.0,
                pt: 70.0,
                qa: 15.0,
            },
        ),
        (
            "shs_arts_sports_health",
            "Arts / Sports / Health & Wellness Electives — DO 015 s 2026",
            WeightPreset {
                ww: 20.0,
                pt: 60.0,
                qa: 20.0,
            },
        ),
        (
            "shs_research_design",
            "Research Electives & Design and Innovation — DO 015 s 2026",
            WeightPreset {
                ww: 40.0,
                pt: 60.0,
                qa: 0.0,
            },
        ),
        (
            "shs_techpro",
            "TechPro Electives — DO 015 s 2026",
            WeightPreset {
                ww: 15.0,
                pt: 65.0,
                qa: 20.0,
            },
        ),
        (
            "shs_work_immersion_do015",
            "Work Immersion — DO 015 s 2026",
            WeightPreset {
                ww: 20.0,
                pt: 80.0,
                qa: 0.0,
            },
        ),
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
