use crate::services::grade_computation::deped_weights::*;

#[test]
fn test_get_preset_language() {
    let preset = get_preset("language").unwrap();
    assert_eq!(preset.ww, 30.0);
    assert_eq!(preset.pt, 50.0);
    assert_eq!(preset.qa, 20.0);
}

#[test]
fn test_get_preset_ap_esp() {
    let preset = get_preset("ap_esp").unwrap();
    assert_eq!(preset.ww, 30.0);
    assert_eq!(preset.pt, 50.0);
    assert_eq!(preset.qa, 20.0);
}

#[test]
fn test_get_preset_math_sci() {
    let preset = get_preset("math_sci").unwrap();
    assert_eq!(preset.ww, 40.0);
    assert_eq!(preset.pt, 40.0);
    assert_eq!(preset.qa, 20.0);
}

#[test]
fn test_get_preset_mapeh_tle() {
    let preset = get_preset("mapeh_tle").unwrap();
    assert_eq!(preset.ww, 20.0);
    assert_eq!(preset.pt, 60.0);
    assert_eq!(preset.qa, 20.0);
}

#[test]
fn test_get_preset_shs_core() {
    let preset = get_preset("shs_core").unwrap();
    assert_eq!(preset.ww, 25.0);
    assert_eq!(preset.pt, 50.0);
    assert_eq!(preset.qa, 25.0);
}

#[test]
fn test_get_preset_shs_academic() {
    let preset = get_preset("shs_academic").unwrap();
    assert_eq!(preset.ww, 25.0);
    assert_eq!(preset.pt, 45.0);
    assert_eq!(preset.qa, 30.0);
}

#[test]
fn test_get_preset_shs_tvl() {
    let preset = get_preset("shs_tvl").unwrap();
    assert_eq!(preset.ww, 25.0);
    assert_eq!(preset.pt, 45.0);
    assert_eq!(preset.qa, 30.0);
}

#[test]
fn test_get_preset_shs_immersion() {
    let preset = get_preset("shs_immersion").unwrap();
    assert_eq!(preset.ww, 35.0);
    assert_eq!(preset.pt, 40.0);
    assert_eq!(preset.qa, 25.0);
}

#[test]
fn test_get_preset_invalid() {
    assert!(get_preset("invalid").is_none());
    assert!(get_preset("").is_none());
    assert!(get_preset("unknown").is_none());
}

#[test]
fn test_get_all_presets_count() {
    let presets = get_all_presets();
    assert_eq!(presets.len(), 8);
}

#[test]
fn test_get_all_presets_contains_language() {
    let presets = get_all_presets();
    let found = presets.iter().find(|(key, _, _)| *key == "language");
    assert!(found.is_some());
    let (_, label, preset) = found.unwrap();
    assert_eq!(*label, "Languages (Mother Tongue, Filipino, English)");
    assert_eq!(preset.ww, 30.0);
}

#[test]
fn test_weights_sum_to_100() {
    let presets = get_all_presets();
    for (_, _, preset) in presets {
        let sum = preset.ww + preset.pt + preset.qa;
        assert!(
            (sum - 100.0).abs() < 0.001,
            "Weights should sum to 100, got {}",
            sum
        );
    }
}

// ===== Transmutation Tests =====

#[test]
fn test_transmute_grade_max() {
    assert_eq!(transmute_grade(100.0), 100);
    assert_eq!(transmute_grade(150.0), 100);
    assert_eq!(transmute_grade(100.5), 100);
}

#[test]
fn test_transmute_grade_above_60() {
    // Formula: floor(75 + (initial - 60) / 1.6)
    assert_eq!(transmute_grade(60.0), 75); // floor(75 + 0) = 75
    assert_eq!(transmute_grade(61.6), 76); // floor(75 + 1) = 76
    assert_eq!(transmute_grade(70.0), 81); // floor(75 + 6.25) = 81
    assert_eq!(transmute_grade(80.0), 87); // floor(75 + 12.5) = 87
    assert_eq!(transmute_grade(90.0), 93); // floor(75 + 18.75) = 93
    assert_eq!(transmute_grade(99.99), 99); // floor(75 + 24.99) = 99
}

#[test]
fn test_transmute_grade_below_60() {
    // Formula: floor(60 + initial / 4)
    assert_eq!(transmute_grade(0.0), 60); // floor(60 + 0) = 60
    assert_eq!(transmute_grade(4.0), 61); // floor(60 + 1) = 61
    assert_eq!(transmute_grade(20.0), 65); // floor(60 + 5) = 65
    assert_eq!(transmute_grade(40.0), 70); // floor(60 + 10) = 70
    assert_eq!(transmute_grade(50.0), 72); // floor(60 + 12.5) = 72
    assert_eq!(transmute_grade(59.0), 74); // floor(60 + 14.75) = 74
    assert_eq!(transmute_grade(59.99), 74); // floor(60 + 14.9975) = 74
}

#[test]
fn test_transmute_grade_boundary_60() {
    assert_eq!(transmute_grade(60.0), 75); // Uses >= 60 formula
}

#[test]
fn test_transmute_grade_negative() {
    // Formula: floor(60 + initial / 4)
    // For negative grades, this goes below 60
    assert_eq!(transmute_grade(-10.0), 57); // floor(60 - 2.5) = 57
    assert_eq!(transmute_grade(-100.0), 35); // floor(60 - 25) = 35
}

// ===== Descriptor Tests =====

#[test]
fn test_get_descriptor_outstanding() {
    assert_eq!(get_descriptor(90), "Outstanding");
    assert_eq!(get_descriptor(95), "Outstanding");
    assert_eq!(get_descriptor(100), "Outstanding");
}

#[test]
fn test_get_descriptor_very_satisfactory() {
    assert_eq!(get_descriptor(85), "Very Satisfactory");
    assert_eq!(get_descriptor(87), "Very Satisfactory");
    assert_eq!(get_descriptor(89), "Very Satisfactory");
}

#[test]
fn test_get_descriptor_satisfactory() {
    assert_eq!(get_descriptor(80), "Satisfactory");
    assert_eq!(get_descriptor(82), "Satisfactory");
    assert_eq!(get_descriptor(84), "Satisfactory");
}

#[test]
fn test_get_descriptor_fairly_satisfactory() {
    assert_eq!(get_descriptor(75), "Fairly Satisfactory");
    assert_eq!(get_descriptor(77), "Fairly Satisfactory");
    assert_eq!(get_descriptor(79), "Fairly Satisfactory");
}

#[test]
fn test_get_descriptor_did_not_meet() {
    assert_eq!(get_descriptor(74), "Did Not Meet Expectations");
    assert_eq!(get_descriptor(60), "Did Not Meet Expectations");
    assert_eq!(get_descriptor(0), "Did Not Meet Expectations");
    assert_eq!(get_descriptor(-10), "Did Not Meet Expectations");
}

// ===== Descriptor Code Tests =====

#[test]
fn test_get_descriptor_code_o() {
    assert_eq!(get_descriptor_code(90), "O");
    assert_eq!(get_descriptor_code(100), "O");
}

#[test]
fn test_get_descriptor_code_vs() {
    assert_eq!(get_descriptor_code(85), "VS");
    assert_eq!(get_descriptor_code(89), "VS");
}

#[test]
fn test_get_descriptor_code_s() {
    assert_eq!(get_descriptor_code(80), "S");
    assert_eq!(get_descriptor_code(84), "S");
}

#[test]
fn test_get_descriptor_code_fs() {
    assert_eq!(get_descriptor_code(75), "FS");
    assert_eq!(get_descriptor_code(79), "FS");
}

#[test]
fn test_get_descriptor_code_dnme() {
    assert_eq!(get_descriptor_code(74), "DNME");
    assert_eq!(get_descriptor_code(60), "DNME");
    assert_eq!(get_descriptor_code(0), "DNME");
}
