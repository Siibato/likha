//! Pure functions for generating submission data.
//!
//! For E2E seeding, submissions are explicitly defined in fixtures.
//! For manual seeding, these generators implement deterministic rules
//! (skip patterns, correctness ratios, etc.) from the seeding spec.

use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::seed_id;
use crate::seed::tools::SeedContext;

/// Generate assessment submissions: every enrolled student submits
pub fn generate_assessment_submissions(
    ctx: &SeedContext,
    assessments: &[AssessmentSpec],
    students: &[UserSpec],
    enrollments: &[EnrollmentSpec],
) -> Vec<AssessmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(2400);

    // Build student index map for quick lookup
    let student_indices: std::collections::HashMap<Uuid, usize> = students
        .iter()
        .enumerate()
        .filter(|(_, s)| s.role == "student")
        .map(|(idx, s)| (s.id, idx))
        .collect();

    // Build class -> students map from enrollments
    let mut class_students: std::collections::HashMap<Uuid, Vec<Uuid>> =
        std::collections::HashMap::new();
    for enrollment in enrollments {
        if student_indices.contains_key(&enrollment.user_id) {
            class_students
                .entry(enrollment.class_id)
                .or_default()
                .push(enrollment.user_id);
        }
    }

    let started_base = ctx.days_ago(10);

    for (assess_idx, assessment) in assessments.iter().enumerate() {
        // Skip deleted assessments
        if assessment.deleted_at.is_some() {
            continue;
        }

        // Get students enrolled in this class
        let enrolled_students = class_students
            .get(&assessment.class_id)
            .cloned()
            .unwrap_or_default();

        for student_id in &enrolled_students {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };

            // All students submit
            let started_at =
                started_base + chrono::Duration::minutes((global_student_idx * 5) as i64);
            let submitted_at =
                Some(started_at + chrono::Duration::minutes(15 + (global_student_idx % 30) as i64));

            // Generate answers
            let answers = generate_assessment_answers(assessment, global_student_idx, assess_idx);

            let total_points: f64 = answers.iter().map(|a| a.points).sum();

            let sub_id = seed_id(
                "assessment_submissions",
                &format!("assess_{}_student_{}", assess_idx, global_student_idx),
            );

            submissions.push(AssessmentSubmissionSpec {
                id: sub_id,
                assessment_id: assessment.id,
                student_id: *student_id,
                started_at,
                submitted_at,
                total_points,
                answers,
            });
        }
    }

    submissions
}

/// Generate answers for a student's assessment submission
fn generate_assessment_answers(
    assessment: &AssessmentSpec,
    student_idx: usize,
    assess_idx: usize,
) -> Vec<SubmissionAnswerSpec> {
    let mut answers = Vec::with_capacity(assessment.questions.len());

    for (q_idx, question) in assessment.questions.iter().enumerate() {
        // Correctness pattern: (student_idx + question_idx) % 4
        // 0=correct, 1=partial, 2=wrong, 3=empty
        let correctness = (student_idx + assess_idx * 10 + q_idx) % 4;

        let (is_correct, points) = match correctness {
            0 => (Some(true), question.points as f64), // Fully correct
            1 => (Some(true), question.points as f64 * 0.8), // Mostly correct (80%)
            2 => (Some(false), question.points as f64 * 0.5), // Mostly wrong (50%)
            _ => (Some(false), 0.0),                   // All wrong
        };

        let choice_ids = if !question.choices.is_empty() {
            // Find the actual correct choice ID from the fixture
            let correct_choice = question.choices.iter().find(|c| c.is_correct);
            let wrong_choices: Vec<_> = question.choices.iter().filter(|c| !c.is_correct).collect();

            if correctness == 0 {
                // Fully correct - pick the real correct choice
                correct_choice
                    .map(|c| vec![c.id])
                    .unwrap_or_else(|| vec![question.choices[0].id])
            } else {
                // Wrong/partial - pick a wrong choice deterministically
                let wrong_idx = (student_idx + assess_idx + q_idx) % wrong_choices.len().max(1);
                wrong_choices
                    .get(wrong_idx)
                    .map(|c| vec![c.id])
                    .unwrap_or_else(|| vec![question.choices[0].id])
            }
        } else {
            vec![]
        };

        let text = if question.choices.is_empty() && correctness != 3 {
            // For identification/enumeration, provide some text
            Some("Student answer".into())
        } else {
            None
        };

        answers.push(SubmissionAnswerSpec {
            question_id: question.id,
            choice_ids,
            text,
            is_correct,
            points,
        });
    }

    answers
}

/// Generate assignment submissions with deterministic patterns
pub fn generate_assignment_submissions(
    ctx: &SeedContext,
    assignments: &[AssignmentSpec],
    students: &[UserSpec],
    teachers: &[UserSpec],
    enrollments: &[EnrollmentSpec],
) -> Vec<AssignmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(1200);

    // Build student index map for quick lookup
    let student_indices: std::collections::HashMap<Uuid, usize> = students
        .iter()
        .enumerate()
        .filter(|(_, s)| s.role == "student")
        .map(|(idx, s)| (s.id, idx))
        .collect();

    // Build class -> students map from enrollments
    let mut class_students: std::collections::HashMap<Uuid, Vec<Uuid>> =
        std::collections::HashMap::new();
    for enrollment in enrollments {
        if student_indices.contains_key(&enrollment.user_id) {
            class_students
                .entry(enrollment.class_id)
                .or_default()
                .push(enrollment.user_id);
        }
    }

    let submitted_at_base = ctx.days_ago(4);

    for (assign_idx, assignment) in assignments.iter().enumerate() {
        // Skip deleted assignments
        if assignment.deleted_at.is_some() {
            continue;
        }

        // Get students enrolled in this class
        let enrolled_students = class_students
            .get(&assignment.class_id)
            .cloned()
            .unwrap_or_default();

        // Get a teacher for grading
        let teacher_id = teachers.get(assign_idx % teachers.len()).map(|t| t.id);

        for student_id in &enrolled_students {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };

            // All submissions are graded
            let submitted_at =
                submitted_at_base + chrono::Duration::hours((global_student_idx % 24) as i64);

            let score = (60 + (global_student_idx % 41)) as i32; // 60-100% score
            let points = (assignment.total_points * score) / 100;
            let feedbacks = [
                "Good work.",
                "Needs improvement.",
                "Excellent!",
                "Well done, keep it up.",
                "Satisfactory.",
            ];
            let feedback = feedbacks[global_student_idx % feedbacks.len()];

            let sub_id = seed_id(
                "assignment_submissions",
                &format!("assign_{}_student_{}", assign_idx, global_student_idx),
            );

            submissions.push(AssignmentSubmissionSpec {
                id: sub_id,
                assignment_id: assignment.id,
                student_id: *student_id,
                text: Some("Assignment submission text.".into()),
                status: "graded".into(),
                points: Some(points),
                feedback: Some(feedback.into()),
                graded_by: teacher_id,
                submitted_at,
                graded_at: Some(ctx.days_ago(3)),
            });
        }
    }

    submissions
}
