//! Demo-2 previous subjects: elementary and JHS subjects per school history entry.

use super::school_history::demo2_school_history;
use super::users::STUDENT_DATA;
use crate::seed::specs::PreviousSubjectSpec;
use crate::seed::tools::seed_id;

// Elementary subjects (G1-G6)
const ELEMENTARY_SUBJECTS: [(&str, Option<&str>); 8] = [
    ("Mother Tongue", Some("language")),
    ("Filipino", Some("language")),
    ("English", Some("language")),
    ("Mathematics", Some("math_sci")),
    ("Science", Some("math_sci")),
    ("Araling Panlipunan", Some("ap_esp")),
    ("MAPEH", Some("mapeh_tle")),
    ("Edukasyon sa Pagpapakatao", Some("ap_esp")),
];

// JHS subjects (G7-G9)
const JHS_SUBJECTS: [(&str, Option<&str>); 8] = [
    ("English", Some("language")),
    ("Filipino", Some("language")),
    ("Mathematics", Some("math_sci")),
    ("Science", Some("math_sci")),
    ("Araling Panlipunan", Some("ap_esp")),
    ("Edukasyon sa Pagpapakatao", Some("ap_esp")),
    ("MAPEH", Some("mapeh_tle")),
    ("TLE", Some("mapeh_tle")),
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

pub fn demo2_previous_subjects() -> Vec<PreviousSubjectSpec> {
    let history = demo2_school_history();
    let mut records = Vec::with_capacity(30 * 9 * 8);

    for (sidx, &(uname, _, _)) in STUDENT_DATA.iter().enumerate() {
        let student_id = crate::seed::fixtures::demo2::uid(uname);
        let student_history: Vec<_> = history
            .iter()
            .filter(|h| h.student_id == student_id)
            .collect();

        for (hidx, hist) in student_history.iter().enumerate() {
            // Use elementary subjects for G1-G6, JHS subjects for G7-G9
            let subjects = if hist.grade_level.starts_with("Grade 1")
                || hist.grade_level.starts_with("Grade 2")
                || hist.grade_level.starts_with("Grade 3")
                || hist.grade_level.starts_with("Grade 4")
                || hist.grade_level.starts_with("Grade 5")
                || hist.grade_level.starts_with("Grade 6")
            {
                &ELEMENTARY_SUBJECTS
            } else {
                &JHS_SUBJECTS
            };

            for (subidx, &(subject_name, subject_group)) in subjects.iter().enumerate() {
                let base: i32 = 78 + ((sidx + hidx + subidx) % 18) as i32;
                let t1 = base;
                let t2 = base + ((sidx + subidx) % 5) as i32 - 2;
                let t3 = base + ((hidx + subidx) % 4) as i32 - 2;
                let t4 = base + ((sidx + hidx) % 3) as i32 - 1;
                let t2 = t2.max(72).min(95);
                let t3 = t3.max(72).min(95);
                let t4 = t4.max(72).min(95);
                let final_grade = ((t1 + t2 + t3 + t4) as f64 / 4.0).round() as i32;

                let id = seed_id(
                    "previous_school_subjects",
                    &format!("{}_{}_{}", uname, hist.grade_level, subject_name),
                );
                records.push(PreviousSubjectSpec {
                    id,
                    student_id,
                    school_history_id: hist.id,
                    subject_name: subject_name.into(),
                    subject_group: subject_group.map(|s| s.into()),
                    term_type: "quarterly".into(),
                    term_grades: vec![Some(t1), Some(t2), Some(t3), Some(t4)],
                    final_grade: Some(final_grade),
                    descriptor: Some(descriptor_for(final_grade).into()),
                });
            }
        }
    }

    records
}
