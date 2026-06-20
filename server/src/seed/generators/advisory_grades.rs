//! Advisory grade generators: manual grade items + deterministic scores + computed term grades.
//! Only for the 3 subject classes (English, Math, Science). Advisory class has no grades.

use std::collections::HashMap;
use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::{SeedContext, seed_id};
use crate::modules::grading::helpers::deped_weights::{get_preset, transmute_grade, WeightPreset};
use crate::seed::fixtures::advisory::classes::cid;

const SUBJECT_CLASSES: &[(&str, &str)] = &[
    ("eng10", "language"),
    ("math10", "math_sci"),
    ("sci10", "math_sci"),
];

const COMPONENTS: &[(&str, &str, f64)] = &[
    ("written_work", "Written Work Quiz", 20.0),
    ("performance_task", "Performance Task", 50.0),
    ("term_assessment", "Term Assessment", 40.0),
];

pub fn generate_grade_records() -> Vec<GradeRecordSpec> {
    let mut records = Vec::new();
    for &(class_key, subject_group) in SUBJECT_CLASSES {
        let preset = get_preset(subject_group).unwrap_or(WeightPreset {
            ww: 40.0,
            pt: 40.0,
            qa: 20.0,
        });
        for term in 1..=4 {
            records.push(GradeRecordSpec {
                class_id: cid(class_key),
                term_number: term,
                ww_weight: preset.ww,
                pt_weight: preset.pt,
                qa_weight: preset.qa,
            });
        }
    }
    records
}

pub fn generate_grade_items() -> Vec<GradeItemSpec> {
    let mut items = Vec::new();
    let mut order = 0;

    for &(class_key, _) in SUBJECT_CLASSES {
        for term in 1..=4 {
            for &(component, title, total_points) in COMPONENTS {
                let item_key = format!("{}_{}_{}", class_key, term, component);
                let id = seed_id("grade_items", &format!("advisory_manual_{}", item_key));
                items.push(GradeItemSpec {
                    id,
                    class_id: cid(class_key),
                    title: format!("{} - T{}", title, term),
                    component: component.into(),
                    term_number: term,
                    total_points,
                    source_type: "manual".into(),
                    source_id: None,
                    order_index: order,
                });
                order += 1;
            }
        }
    }

    items
}

pub fn generate_grade_scores(
    students: &[UserSpec],
    enrollments: &[EnrollmentSpec],
    grade_items: &[GradeItemSpec],
) -> Vec<GradeScoreSpec> {
    let mut scores = Vec::new();

    let mut class_students: HashMap<Uuid, Vec<usize>> = HashMap::new();
    for (idx, student) in students.iter().enumerate() {
        if student.role != "student" {
            continue;
        }
        for e in enrollments {
            if e.user_id == student.id {
                class_students.entry(e.class_id).or_default().push(idx);
            }
        }
    }

    for item in grade_items {
        let enrolled = class_students.get(&item.class_id).cloned().unwrap_or_default();
        for &student_idx in &enrolled {
            let student = &students[student_idx];
            let base_pct = 70.0 + ((student_idx + item.order_index as usize) % 25) as f64;
            let score = (base_pct / 100.0) * item.total_points;
            let has_override = (student_idx + item.order_index as usize) % 15 == 0;
            let override_score = if has_override {
                Some(((base_pct + 5.0) / 100.0) * item.total_points)
            } else {
                None
            };

            scores.push(GradeScoreSpec {
                grade_item_id: item.id,
                student_id: student.id,
                score: Some(score),
                is_auto_populated: false,
                override_score,
                component: item.component.clone(),
                term_number: item.term_number,
            });
        }
    }

    scores
}

pub fn generate_term_grades(
    students: &[UserSpec],
    grade_records: &[GradeRecordSpec],
    grade_scores: &[GradeScoreSpec],
    grade_items: &[GradeItemSpec],
    enrollments: &[EnrollmentSpec],
    ctx: &SeedContext,
) -> Vec<TermGradeSpec> {
    let mut term_grades = Vec::new();

    let mut class_students: HashMap<Uuid, Vec<usize>> = HashMap::new();
    for (idx, student) in students.iter().enumerate() {
        if student.role != "student" {
            continue;
        }
        for e in enrollments {
            if e.user_id == student.id {
                class_students.entry(e.class_id).or_default().push(idx);
            }
        }
    }

    let item_map: HashMap<Uuid, (String, f64)> = grade_items
        .iter()
        .map(|i| (i.id, (i.component.clone(), i.total_points)))
        .collect();

    for record in grade_records {
        let enrolled = class_students.get(&record.class_id).cloned().unwrap_or_default();
        for &student_idx in &enrolled {
            let student_id = students[student_idx].id;

            let student_scores: Vec<_> = grade_scores
                .iter()
                .filter(|s| {
                    s.student_id == student_id
                        && s.term_number == record.term_number
                })
                .collect();

            let mut ww_sum = 0.0;
            let mut ww_total = 0.0;
            let mut pt_sum = 0.0;
            let mut pt_total = 0.0;
            let mut qa_sum = 0.0;
            let mut qa_total = 0.0;

            for s in &student_scores {
                let effective = s.override_score.or(s.score).unwrap_or(0.0);
                if let Some((component, total_points)) = item_map.get(&s.grade_item_id) {
                    match component.as_str() {
                        "written_work" => {
                            ww_sum += effective;
                            ww_total += *total_points;
                        }
                        "performance_task" => {
                            pt_sum += effective;
                            pt_total += *total_points;
                        }
                        "term_assessment" => {
                            qa_sum += effective;
                            qa_total += *total_points;
                        }
                        _ => {}
                    }
                }
            }

            let ww_pct = if ww_total > 0.0 {
                (ww_sum / ww_total) * 100.0
            } else {
                0.0
            };
            let pt_pct = if pt_total > 0.0 {
                (pt_sum / pt_total) * 100.0
            } else {
                0.0
            };
            let qa_pct = if qa_total > 0.0 {
                (qa_sum / qa_total) * 100.0
            } else {
                0.0
            };

            let initial_grade = ww_pct * (record.ww_weight / 100.0)
                + pt_pct * (record.pt_weight / 100.0)
                + qa_pct * (record.qa_weight / 100.0);

            let transmuted = transmute_grade(initial_grade);

            term_grades.push(TermGradeSpec {
                class_id: record.class_id,
                student_id,
                term_number: record.term_number,
                initial_grade: Some(initial_grade),
                transmuted_grade: Some(transmuted),
                is_locked: false,
            });
        }
    }

    term_grades
}
