//! Demo-2 school history: G1-G9 history per student (elementary + JHS).

use super::users::STUDENT_DATA;
use crate::seed::specs::SchoolHistorySpec;
use crate::seed::tools::seed_id;
use chrono::NaiveDate;

// Elementary years (G1-G6)
const ELEMENTARY: [(&str, &str, &str, &str, &str); 6] = [
    ("Grade 1", "2016-2017", "Bautista Elementary School", "2016-06-13", "2017-04-07"),
    ("Grade 2", "2017-2018", "Bautista Elementary School", "2017-06-12", "2018-04-05"),
    ("Grade 3", "2018-2019", "Bautista Elementary School", "2018-06-11", "2019-04-04"),
    ("Grade 4", "2019-2020", "Bautista Elementary School", "2019-06-10", "2020-04-03"),
    ("Grade 5", "2020-2021", "Bautista Elementary School", "2020-06-08", "2021-04-02"),
    ("Grade 6", "2021-2022", "Bautista Elementary School", "2021-06-07", "2022-04-01"),
];

// Junior High School years (G7-G9)
const JHS: [(&str, &str, &str, &str, &str); 3] = [
    ("Grade 7", "2022-2023", "Rizal High School", "2022-06-13", "2023-04-07"),
    ("Grade 8", "2023-2024", "Rizal High School", "2023-06-12", "2024-04-05"),
    ("Grade 9", "2024-2025", "Rizal High School", "2024-06-10", "2025-04-04"),
];

// Alternative schools for transfer students
const ALT_SCHOOLS: [(&str, &str); 3] = [
    ("Manila Central School", "MCS-001"),
    ("Pasig City Science High School", "PCSH-002"),
    ("Quezon City High School", "QCHS-003"),
];

pub fn demo2_school_history() -> Vec<SchoolHistorySpec> {
    let mut records = Vec::with_capacity(270);

    for (sidx, &(uname, _, _)) in STUDENT_DATA.iter().enumerate() {
        // Use alternative school for some students to add realism
        let use_alt_school = sidx % 8 == 0; // Every 8th student (4 students total)
        let (alt_school_name, alt_school_id) = ALT_SCHOOLS[(sidx / 8) % 3];

        // Elementary years
        for (grade_level, school_year, school_name, date_from, date_to) in &ELEMENTARY {
            let (final_school_name, final_school_id) = if use_alt_school {
                (alt_school_name, Some(alt_school_id.into()))
            } else {
                (*school_name, Some("BES-001".into()))
            };

            let id = seed_id(
                "student_school_history",
                &format!("{}_{}_{}", uname, grade_level, school_year),
            );
            records.push(SchoolHistorySpec {
                id,
                student_id: crate::seed::fixtures::demo2::uid(uname),
                school_name: final_school_name.into(),
                school_id: final_school_id,
                grade_level: (*grade_level).into(),
                school_year: (*school_year).into(),
                section: Some("Section 1".into()),
                date_from: Some(NaiveDate::parse_from_str(date_from, "%Y-%m-%d").unwrap()),
                date_to: Some(NaiveDate::parse_from_str(date_to, "%Y-%m-%d").unwrap()),
                record_type: "previous".into(),
            });
        }

        // JHS years
        for (grade_level, school_year, school_name, date_from, date_to) in &JHS {
            let (final_school_name, final_school_id) = if use_alt_school && sidx % 8 < 2 {
                // Some students transferred for JHS
                (alt_school_name, Some(alt_school_id.into()))
            } else {
                (*school_name, Some("RHS-001".into()))
            };

            let id = seed_id(
                "student_school_history",
                &format!("{}_{}_{}", uname, grade_level, school_year),
            );
            records.push(SchoolHistorySpec {
                id,
                student_id: crate::seed::fixtures::demo2::uid(uname),
                school_name: final_school_name.into(),
                school_id: final_school_id,
                grade_level: (*grade_level).into(),
                school_year: (*school_year).into(),
                section: Some("Rizal".into()),
                date_from: Some(NaiveDate::parse_from_str(date_from, "%Y-%m-%d").unwrap()),
                date_to: Some(NaiveDate::parse_from_str(date_to, "%Y-%m-%d").unwrap()),
                record_type: "previous".into(),
            });
        }
    }

    records
}
