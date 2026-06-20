//! Advisory previous subjects: ~8 standard DepEd JHS subjects per school history entry.

use crate::seed::specs::PreviousSubjectSpec;
use crate::seed::tools::seed_id;
use super::users::{uid, STUDENT_DATA};
use super::school_history::advisory_school_history;

const SUBJECTS: [(&str, &str); 8] = [
    ("English", "language"),
    ("Filipino", "language"),
    ("Mathematics", "math_sci"),
    ("Science", "math_sci"),
    ("Araling Panlipunan", "ap_esp"),
    ("Edukasyon sa Pagpapakatao", "ap_esp"),
    ("MAPEH", "mapeh_tle"),
    ("TLE", "mapeh_tle"),
];

fn descriptor_for(grade: i32) -> &'static str {
    match grade {
        90..=100 => "Outstanding",
        85..=89 => "Very Satisfactory",
        80..=84 => "Satisfactory",
        75..=79 => "Fairly Satisfactory",
        _ => "Did Not Meet Expectations",
    }
}

pub fn advisory_previous_subjects() -> Vec<PreviousSubjectSpec> {
    let history = advisory_school_history();
    let mut records = Vec::with_capacity(30 * 3 * 8);

    for (sidx, &(uname, _)) in STUDENT_DATA.iter().enumerate() {
        let student_id = uid(uname);
        let student_history: Vec<_> = history.iter()
            .filter(|h| h.student_id == student_id)
            .collect();

        for (hidx, hist) in student_history.iter().enumerate() {
            for (subidx, &(subject_name, subject_group)) in SUBJECTS.iter().enumerate() {
                let base: i32 = 78 + ((sidx + hidx + subidx) % 18) as i32;
                let q1 = base;
                let q2 = base + ((sidx + subidx) % 5) as i32 - 2;
                let q3 = base + ((hidx + subidx) % 4) as i32 - 2;
                let q4 = base + ((sidx + hidx) % 3) as i32 - 1;
                let q2 = q2.max(72).min(95);
                let q3 = q3.max(72).min(95);
                let q4 = q4.max(72).min(95);
                let final_grade = ((q1 + q2 + q3 + q4) as f64 / 4.0).round() as i32;

                let id = seed_id(
                    "previous_school_subjects",
                    &format!("{}_{}_{}", uname, hist.grade_level, subject_name),
                );
                records.push(PreviousSubjectSpec {
                    id,
                    student_id,
                    school_history_id: hist.id,
                    subject_name: subject_name.into(),
                    subject_group: Some(subject_group.into()),
                    q1_grade: Some(q1),
                    q2_grade: Some(q2),
                    q3_grade: Some(q3),
                    q4_grade: Some(q4),
                    final_grade: Some(final_grade),
                    descriptor: Some(descriptor_for(final_grade).into()),
                });
            }
        }
    }

    records
}
