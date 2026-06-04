//! Pure functions for generating submission data.
//!
//! For E2E seeding, submissions are explicitly defined in fixtures.
//! For manual seeding, these generators implement deterministic rules
//! (skip patterns, correctness ratios, etc.) from the seeding spec.

use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use crate::seed::tools::seed_id;

/// Generate assessment submissions with deterministic skip patterns
pub fn generate_assessment_submissions(
    ctx: &SeedContext,
    assessments: &[AssessmentSpec],
    students: &[UserSpec],
    enrollments: &[EnrollmentSpec],
) -> Vec<AssessmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(1200);

    // Build student index map for quick lookup
    let student_indices: std::collections::HashMap<Uuid, usize> = students
        .iter()
        .enumerate()
        .filter(|(_, s)| s.role == "student")
        .map(|(idx, s)| (s.id, idx))
        .collect();

    // Build class -> students map from enrollments
    let mut class_students: std::collections::HashMap<Uuid, Vec<Uuid>> = std::collections::HashMap::new();
    for enrollment in enrollments {
        if student_indices.contains_key(&enrollment.user_id) {
            class_students.entry(enrollment.class_id).or_default().push(enrollment.user_id);
        }
    }

    let started_base = ctx.days_ago(10);

    for (assess_idx, assessment) in assessments.iter().enumerate() {
        // Skip deleted assessments
        if assessment.deleted_at.is_some() {
            continue;
        }

        // Get students enrolled in this class
        let enrolled_students = class_students.get(&assessment.class_id).cloned().unwrap_or_default();

        for (student_idx_in_class, student_id) in enrolled_students.iter().enumerate() {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };

            // Skip rule: (student_idx + assessment_idx) % 7 == 0
            if (global_student_idx + assess_idx) % 7 == 0 {
                continue;
            }

            // 90% submitted, 10% in-progress
            let is_submitted = (global_student_idx + assess_idx) % 10 != 0;

            let started_at = started_base + chrono::Duration::minutes((global_student_idx * 5) as i64);
            let submitted_at = if is_submitted {
                Some(started_at + chrono::Duration::minutes(15 + (global_student_idx % 30) as i64))
            } else {
                None
            };

            // Generate answers
            let answers = generate_assessment_answers(
                assessment,
                global_student_idx,
                assess_idx,
            );

            let total_points: f64 = answers.iter().map(|a| a.points).sum();

            let sub_id = seed_id("assessment_submissions", &format!("assess_{}_student_{}", assess_idx, global_student_idx));

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
            _ => (Some(false), 0.0), // All wrong
        };

        let choice_ids = if !question.choices.is_empty() {
            // For MCQ: pick a choice based on correctness
            if correctness == 0 {
                // Correct answer - pick the first (correct) choice
                vec![question.choices[0].id]
            } else {
                // Wrong answer - pick a different choice
                vec![question.choices[1].id]
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
    let mut class_students: std::collections::HashMap<Uuid, Vec<Uuid>> = std::collections::HashMap::new();
    for enrollment in enrollments {
        if student_indices.contains_key(&enrollment.user_id) {
            class_students.entry(enrollment.class_id).or_default().push(enrollment.user_id);
        }
    }

    let submitted_at_base = ctx.days_ago(4);

    for (assign_idx, assignment) in assignments.iter().enumerate() {
        // Skip deleted assignments
        if assignment.deleted_at.is_some() {
            continue;
        }

        // Get students enrolled in this class
        let enrolled_students = class_students.get(&assignment.class_id).cloned().unwrap_or_default();

        // Get a teacher for grading
        let teacher_id = teachers.get(assign_idx % teachers.len()).map(|t| t.id);

        for (student_idx_in_class, student_id) in enrolled_students.iter().enumerate() {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };

            // Skip rule: (student_idx + assignment_idx) % 7 == 0
            if (global_student_idx + assign_idx) % 7 == 0 {
                continue;
            }

            // 50% submitted (not graded), 50% graded
            let is_graded = (global_student_idx + assign_idx) % 2 == 0;

            let submitted_at = submitted_at_base + chrono::Duration::hours((global_student_idx % 24) as i64);

            let (status, points, feedback, graded_by, graded_at) = if is_graded {
                let score = (70 + (global_student_idx % 30)) as i32; // 70-100% score
                let points = (assignment.total_points * score) / 100;
                let feedbacks = ["Good work.", "Needs improvement.", "Excellent!"];
                let feedback = feedbacks[global_student_idx % 3];
                (
                    "graded".into(),
                    Some(points),
                    Some(feedback.into()),
                    teacher_id,
                    Some(ctx.days_ago(3)),
                )
            } else {
                (
                    "submitted".into(),
                    None,
                    None,
                    None,
                    None,
                )
            };

            let sub_id = seed_id("assignment_submissions", &format!("assign_{}_student_{}", assign_idx, global_student_idx));

            submissions.push(AssignmentSubmissionSpec {
                id: sub_id,
                assignment_id: assignment.id,
                student_id: *student_id,
                text: Some("Assignment submission text.".into()),
                status,
                points,
                feedback,
                graded_by,
                submitted_at,
                graded_at,
            });
        }
    }

    submissions
}
