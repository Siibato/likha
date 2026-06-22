//! Demo grade generators that derive scores from actual submissions.

use std::collections::HashMap;
use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use crate::modules::grading::helpers::deped_weights::transmute_grade;

/// Generate grade records for each class × each term.
pub fn generate_grade_records(classes: &[ClassSpec]) -> Vec<GradeRecordSpec> {
    let mut records = Vec::new();
    for class in classes {
        if class.deleted_at.is_some() {
            continue;
        }
        let (ww, pt, qa) = if class.title.contains("Science") {
            (40.0, 40.0, 20.0)
        } else {
            (50.0, 30.0, 20.0)
        };
        for term in 1..=4 {
            records.push(GradeRecordSpec {
                class_id: class.id,
                term_number: term,
                ww_weight: ww,
                pt_weight: pt,
                qa_weight: qa,
            });
        }
    }
    records
}

/// Generate grade items for published assessments and assignments.
pub fn generate_grade_items(
    assessments: &[AssessmentSpec],
    assignments: &[AssignmentSpec],
    ctx: &SeedContext,
) -> Vec<GradeItemSpec> {
    let mut items = Vec::new();
    let now = ctx.now();

    for a in assessments {
        if !a.is_published || a.deleted_at.is_some() || a.open_at > now {
            continue;
        }
        let id = crate::seed::tools::seed_id("grade_items", &format!("assess_{}_{}", a.id, a.term_number));
        items.push(GradeItemSpec {
            id,
            class_id: a.class_id,
            title: a.title.clone(),
            component: a.component.clone(),
            term_number: a.term_number,
            total_points: a.total_points as f64,
            source_type: "assessment".into(),
            source_id: Some(a.id.to_string()),
            order_index: 0,
        });
    }

    for a in assignments {
        if !a.is_published || a.deleted_at.is_some() || a.due_at > now {
            continue;
        }
        let id = crate::seed::tools::seed_id("grade_items", &format!("assign_{}_{}", a.id, a.term_number));
        items.push(GradeItemSpec {
            id,
            class_id: a.class_id,
            title: a.title.clone(),
            component: a.component.clone(),
            term_number: a.term_number,
            total_points: a.total_points as f64,
            source_type: "assignment".into(),
            source_id: Some(a.id.to_string()),
            order_index: 0,
        });
    }

    items
}

/// Generate grade scores from actual submission data.
pub fn generate_grade_scores(
    grade_items: &[GradeItemSpec],
    students: &[UserSpec],
    assessment_submissions: &[AssessmentSubmissionSpec],
    assignment_submissions: &[AssignmentSubmissionSpec],
    enrollments: &[EnrollmentSpec],
) -> Vec<GradeScoreSpec> {
    let mut scores = Vec::new();

    // Build lookup maps
    let assessment_scores: HashMap<(Uuid, Uuid), f64> = assessment_submissions
        .iter()
        .map(|s| ((s.assessment_id, s.student_id), s.total_points))
        .collect();

    let assignment_scores: HashMap<(Uuid, Uuid), i32> = assignment_submissions
        .iter()
        .filter(|s| s.points.is_some())
        .map(|s| ((s.assignment_id, s.student_id), s.points.unwrap()))
        .collect();

    let mut class_students: HashMap<Uuid, Vec<Uuid>> = HashMap::new();
    for enrollment in enrollments {
        if students.iter().any(|s| s.id == enrollment.user_id && s.role == "student") {
            class_students.entry(enrollment.class_id).or_default().push(enrollment.user_id);
        }
    }

    for item in grade_items {
        let enrolled = class_students.get(&item.class_id).cloned().unwrap_or_default();
        for student_id in &enrolled {
            let score = match item.source_type.as_str() {
                "assessment" => {
                    item.source_id.as_ref()
                        .and_then(|sid| Uuid::parse_str(sid).ok())
                        .and_then(|uuid| assessment_scores.get(&(uuid, *student_id)))
                        .copied()
                }
                "assignment" => {
                    item.source_id.as_ref()
                        .and_then(|sid| Uuid::parse_str(sid).ok())
                        .and_then(|uuid| assignment_scores.get(&(uuid, *student_id)))
                        .map(|&p| p as f64)
                }
                _ => None,
            };

            scores.push(GradeScoreSpec {
                grade_item_id: item.id,
                student_id: *student_id,
                score,
                is_auto_populated: true,
                override_score: None,
                component: item.component.clone(),
                term_number: item.term_number,
            });
        }
    }

    scores
}

/// Compute term grades from grade scores using DepEd formulas.
pub fn generate_term_grades(
    grade_records: &[GradeRecordSpec],
    grade_scores: &[GradeScoreSpec],
    grade_items: &[GradeItemSpec],
    students: &[UserSpec],
    enrollments: &[EnrollmentSpec],
    _ctx: &SeedContext,
) -> Vec<TermGradeSpec> {
    let mut term_grades = Vec::new();

    let mut class_students: HashMap<Uuid, Vec<Uuid>> = HashMap::new();
    for enrollment in enrollments {
        if students.iter().any(|s| s.id == enrollment.user_id && s.role == "student") {
            class_students.entry(enrollment.class_id).or_default().push(enrollment.user_id);
        }
    }

    let item_map: HashMap<Uuid, (String, f64)> = grade_items.iter()
        .map(|i| (i.id, (i.component.clone(), i.total_points)))
        .collect();

    for record in grade_records {
        let enrolled = class_students.get(&record.class_id).cloned().unwrap_or_default();
        for (_student_idx, student_id) in enrolled.iter().enumerate() {
            let student_scores: Vec<&GradeScoreSpec> = grade_scores.iter()
                .filter(|s| s.student_id == *student_id && s.term_number == record.term_number)
                .collect();

            let mut ww_sum = 0.0;
            let mut ww_total = 0.0;
            let mut pt_sum = 0.0;
            let mut pt_total = 0.0;
            let mut qa_sum = 0.0;
            let mut qa_total = 0.0;

            for s in student_scores {
                let effective = s.override_score.or(s.score).unwrap_or(0.0);
                if let Some((component, total_points)) = item_map.get(&s.grade_item_id) {
                    match component.as_str() {
                        "written_work" => { ww_sum += effective; ww_total += *total_points; }
                        "performance_task" => { pt_sum += effective; pt_total += *total_points; }
                        "term_assessment" => { qa_sum += effective; qa_total += *total_points; }
                        _ => {}
                    }
                }
            }

            let ww_pct = if ww_total > 0.0 { (ww_sum / ww_total) * 100.0 } else { 0.0 };
            let pt_pct = if pt_total > 0.0 { (pt_sum / pt_total) * 100.0 } else { 0.0 };
            let qa_pct = if qa_total > 0.0 { (qa_sum / qa_total) * 100.0 } else { 0.0 };

            let initial_grade = ww_pct * (record.ww_weight / 100.0)
                + pt_pct * (record.pt_weight / 100.0)
                + qa_pct * (record.qa_weight / 100.0);

            let transmuted = transmute_grade(initial_grade);

            term_grades.push(TermGradeSpec {
                class_id: record.class_id,
                student_id: *student_id,
                term_number: record.term_number,
                initial_grade: Some(initial_grade),
                transmuted_grade: Some(transmuted),
                is_locked: false,
            });
        }
    }

    term_grades
}
