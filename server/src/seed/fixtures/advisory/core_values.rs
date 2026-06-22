//! Advisory core values: 4 DepEd core values × 4 terms per student.

use crate::seed::specs::CoreValuesSpec;
use crate::seed::tools::seed_id;
use super::users::{uid, STUDENT_DATA};
use super::classes::cid;

const CORE_VALUE_IDS: [i32; 4] = [1, 2, 3, 4];

const MARKINGS: [&str; 4] = ["AO", "SO", "RO", "NO"];

pub fn advisory_core_values() -> Vec<CoreValuesSpec> {
    let mut records = Vec::with_capacity(480);
    let advisory_class = cid("adv10");
    let school_year = "2025-2026";

    for (sidx, &(uname, _, _)) in STUDENT_DATA.iter().enumerate() {
        for term in 1..=4 {
            for (vidx, &core_value_id) in CORE_VALUE_IDS.iter().enumerate() {
                let marking = MARKINGS[(sidx + vidx + term) % 4];
                let id = seed_id(
                    "core_values_records",
                    &format!("{}_{}_{}_{}", uname, term, core_value_id, school_year),
                );
                records.push(CoreValuesSpec {
                    id,
                    student_id: uid(uname),
                    class_id: advisory_class,
                    school_year: school_year.into(),
                    term_number: term as i32,
                    core_value_id,
                    marking: marking.into(),
                });
            }
        }
    }

    records
}
