//! Advisory core values: 4 DepEd core values × 4 quarters per student.

use crate::seed::specs::CoreValuesSpec;
use crate::seed::tools::seed_id;
use super::users::{uid, STUDENT_DATA};
use super::classes::cid;

const CORE_VALUES: [(&str, &str); 4] = [
    (
        "Maka-Diyos",
        "Shows respect for all beliefs and faiths; participates in spiritual activities",
    ),
    (
        "Makatao",
        "Demonstrates empathy and compassion toward peers and community members",
    ),
    (
        "Maka-Kalikasan",
        "Shows care for the environment by participating in eco-friendly practices",
    ),
    (
        "Maka-bansa",
        "Expresses pride in being Filipino and contributes to nation-building",
    ),
];

const MARKINGS: [&str; 4] = ["AO", "SO", "RO", "NO"];

pub fn advisory_core_values() -> Vec<CoreValuesSpec> {
    let mut records = Vec::with_capacity(480);
    let advisory_class = cid("adv10");
    let school_year = "2025-2026";

    for (sidx, &(uname, _)) in STUDENT_DATA.iter().enumerate() {
        for quarter in 1..=4 {
            for (vidx, &(core_value, behavior)) in CORE_VALUES.iter().enumerate() {
                let marking = MARKINGS[(sidx + vidx + quarter) % 4];
                let id = seed_id(
                    "core_values_records",
                    &format!("{}_{}_{}_{}", uname, quarter, core_value, school_year),
                );
                records.push(CoreValuesSpec {
                    id,
                    student_id: uid(uname),
                    class_id: advisory_class,
                    school_year: school_year.into(),
                    term_number: quarter as i32,
                    core_value: core_value.into(),
                    behavior_statement: behavior.into(),
                    marking: marking.into(),
                });
            }
        }
    }

    records
}
