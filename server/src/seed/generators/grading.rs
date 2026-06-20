//! Pure functions for generating grading data.
//!
//! Grade scores and term grades are computed from submission data
//! using the deterministic rules from the seeding spec.

use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn generate_grade_scores(
    _ctx: &SeedContext,
    _submissions: &[AssessmentSubmissionSpec],
    _grade_item_mappings: &[(Uuid, Uuid)], // (source_id, grade_item_id)
) -> Vec<GradeScoreSpec> {
    // TODO: Implement for manual seed
    // - One score per student per grade item
    // - 5% have override_score set (teacher adjustment)
    vec![]
}

pub fn generate_term_grades(
    ctx: &SeedContext,
    classes: &[ClassSpec],
    students: &[UserSpec],
    grade_scores: &[GradeScoreSpec],
    enrollments: &[EnrollmentSpec],
) -> Vec<TermGradeSpec> {
    use crate::modules::grading::helpers::deped_weights::transmute_grade;
    use uuid::Uuid;

    let mut term_grades = Vec::new();

    // Build class_id -> enrolled student_ids lookup (only actual enrollments)
    let mut class_students: std::collections::HashMap<Uuid, Vec<usize>> = std::collections::HashMap::new();
    for (idx, student) in students.iter().enumerate() {
        if student.role != "student" {
            continue;
        }
        for enrollment in enrollments {
            if enrollment.user_id == student.id {
                class_students.entry(enrollment.class_id).or_default().push(idx);
            }
        }
    }

    // Generate term records per non-deleted class (T1-T4)
    for class in classes {
        if class.deleted_at.is_some() {
            continue;
        }
        for term in 1..=4 {
            let enrolled = class_students.get(&class.id).cloned().unwrap_or_default();

            for &student_idx in &enrolled {
                let student_id = students[student_idx].id;

                // Compute initial grade (simplified: average of scores / 100 * 100)
                let student_scores: Vec<f64> = grade_scores
                    .iter()
                    .filter(|s| s.student_id == student_id)
                    .filter_map(|s| s.score)
                    .collect();

                let initial_grade = if student_scores.is_empty() {
                    0.0
                } else {
                    student_scores.iter().sum::<f64>() / student_scores.len() as f64
                };

                let transmuted = transmute_grade(initial_grade);

                term_grades.push(TermGradeSpec {
                    class_id: class.id,
                    student_id,
                    term_number: term,
                    initial_grade: Some(initial_grade),
                    transmuted_grade: Some(transmuted),
                    is_locked: false,
                });
            }
        }
    }

    term_grades
}
