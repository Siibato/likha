//! Advisory previous attendance: ~10 months per school year per student.

use crate::seed::specs::PreviousAttendanceSpec;
use crate::seed::tools::seed_id;
use super::users::{uid, STUDENT_DATA};
use super::school_history::advisory_school_history;

const PREV_MONTHS: [(&str, i32); 10] = [
    ("June", 22),
    ("July", 23),
    ("August", 22),
    ("September", 22),
    ("October", 23),
    ("November", 22),
    ("December", 15),
    ("January", 22),
    ("February", 20),
    ("March", 22),
];

pub fn advisory_previous_attendance() -> Vec<PreviousAttendanceSpec> {
    let history = advisory_school_history();
    let mut records = Vec::with_capacity(30 * 3 * 10);

    for (sidx, &(uname, _)) in STUDENT_DATA.iter().enumerate() {
        let student_id = uid(uname);
        let student_history: Vec<_> = history.iter()
            .filter(|h| h.student_id == student_id)
            .collect();

        for (hidx, hist) in student_history.iter().enumerate() {
            for (month_idx, &(month, school_days)) in PREV_MONTHS.iter().enumerate() {
                let days_present = school_days - ((sidx + hidx + month_idx) % 6) as i32;
                let id = seed_id(
                    "previous_school_attendance",
                    &format!("{}_{}_{}_{}", uname, hist.school_year, month, hist.grade_level),
                );
                records.push(PreviousAttendanceSpec {
                    id,
                    student_id,
                    school_history_id: hist.id,
                    school_year: hist.school_year.clone(),
                    month: month.into(),
                    school_days,
                    days_present,
                });
            }
        }
    }

    records
}
