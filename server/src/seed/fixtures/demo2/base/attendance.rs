//! Demo-2 attendance: 12 months per student linked to advisory class.

use super::super::cid;
use super::users::STUDENT_DATA;
use crate::seed::specs::AttendanceSpec;
use crate::seed::tools::seed_id;

const MONTHS: [(&str, i32); 12] = [
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
    ("April", 18),
    ("TOT", 0),
];

pub fn demo2_attendance() -> Vec<AttendanceSpec> {
    let mut records = Vec::with_capacity(360);
    let advisory_class = cid("adv_mahogany");
    let school_year = "2025-2026";

    for (idx, &(uname, _, _)) in STUDENT_DATA.iter().enumerate() {
        for (month_idx, &(month, school_days)) in MONTHS.iter().enumerate() {
            if school_days == 0 {
                continue;
            }
            let days_present = school_days - ((idx + month_idx) % 5) as i32;
            let id = seed_id(
                "attendance_records",
                &format!("{}_{}_{}", uname, school_year, month),
            );
            records.push(AttendanceSpec {
                id,
                student_id: crate::seed::fixtures::demo2::uid(uname),
                class_id: advisory_class,
                school_year: school_year.into(),
                month: month.into(),
                school_days,
                days_present,
            });
        }
    }

    records
}
