//! Advisory school history: G7, G8, G9 history per student.

use super::users::{uid, STUDENT_DATA};
use crate::seed::specs::SchoolHistorySpec;
use crate::seed::tools::seed_id;
use chrono::NaiveDate;

const HISTORY: [(&str, &str, &str, &str, &str); 3] = [
    (
        "Grade 7",
        "2022-2023",
        "Rizal High School",
        "2022-06-13",
        "2023-04-07",
    ),
    (
        "Grade 8",
        "2023-2024",
        "Rizal High School",
        "2023-06-12",
        "2024-04-05",
    ),
    (
        "Grade 9",
        "2024-2025",
        "Rizal High School",
        "2024-06-10",
        "2025-04-04",
    ),
];

pub fn advisory_school_history() -> Vec<SchoolHistorySpec> {
    let mut records = Vec::with_capacity(90);

    for &(uname, _, _) in &STUDENT_DATA {
        for &(grade_level, school_year, school_name, date_from, date_to) in &HISTORY {
            let id = seed_id(
                "student_school_history",
                &format!("{}_{}_{}", uname, grade_level, school_year),
            );
            records.push(SchoolHistorySpec {
                id,
                student_id: uid(uname),
                school_name: school_name.into(),
                school_id: Some("RHS-001".into()),
                grade_level: grade_level.into(),
                school_year: school_year.into(),
                section: Some("Rizal".into()),
                date_from: Some(NaiveDate::parse_from_str(date_from, "%Y-%m-%d").unwrap()),
                date_to: Some(NaiveDate::parse_from_str(date_to, "%Y-%m-%d").unwrap()),
                record_type: "previous".into(),
            });
        }
    }

    records
}
