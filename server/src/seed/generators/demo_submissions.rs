//! Demo submission generators with tiered, context-aware answers.

use std::collections::HashMap;
use uuid::Uuid;

use crate::seed::fixtures::demo::TermAnswers;
use crate::seed::specs::*;
use crate::seed::tools::seed_id;
use crate::seed::tools::SeedContext;

/// Determine student tier based on index for consistent grade distribution.
/// - Students 0–4: Tier 0 (Excellent)
/// - Students 5–14: Tier 1 (Good)
/// - Students 15–24: Tier 2 (Satisfactory)
/// - Students 25–29: Tier 3 (Developing)
fn student_tier(student_idx: usize) -> usize {
    match student_idx {
        0..=4 => 0,
        5..=14 => 1,
        15..=24 => 2,
        _ => 3,
    }
}

/// Deterministic correctness pattern for MC/ID questions.
fn is_correct(tier: usize, student_idx: usize, assess_idx: usize, q_idx: usize) -> bool {
    let pattern = (student_idx + assess_idx * 7 + q_idx) % 10;
    match tier {
        0 => pattern < 9, // 90%
        1 => pattern < 8, // 80%
        2 => pattern < 6, // 60%
        _ => pattern < 4, // 40%
    }
}

/// Essay points based on tier.
fn essay_points(tier: usize, max_points: i32) -> f64 {
    let pct = match tier {
        0 => 0.95,
        1 => 0.85,
        2 => 0.77,
        _ => 0.72,
    };
    (max_points as f64 * pct).round()
}

/// Assignment points based on tier.
fn assignment_points(tier: usize, max_points: i32) -> i32 {
    let pct = match tier {
        0 => 0.95,
        1 => 0.85,
        2 => 0.77,
        _ => 0.72,
    };
    (max_points as f64 * pct).round() as i32
}

/// Feedback based on tier.
fn assignment_feedback(tier: usize) -> &'static str {
    match tier {
        0 => "Excellent work! Thorough analysis with clear examples.",
        1 => "Good work. Your explanation is mostly clear, but could include more specific examples.",
        2 => "Satisfactory. Please review the module and expand your answer with more details.",
        _ => "Good attempt. Please review the relevant module section and expand your explanation with more evidence.",
    }
}

/// Build a map from assessment ID to term key ("t1", "t2", "t3", "t4").
fn assessment_term_map() -> HashMap<Uuid, &'static str> {
    let mut map = HashMap::new();
    for t in ["t1", "t2", "t3", "t4"] {
        map.insert(seed_id("assessments", &format!("{t}_quiz1")), t);
        map.insert(seed_id("assessments", &format!("{t}_quiz2")), t);
        map.insert(seed_id("assessments", &format!("{t}_exam")), t);
    }
    map
}

/// Build a map from assignment ID to (term key, assignment number).
fn assignment_term_map() -> HashMap<Uuid, (&'static str, usize)> {
    let mut map = HashMap::new();
    for t in ["t1", "t2", "t3", "t4"] {
        map.insert(seed_id("assignments", &format!("{t}_assign1")), (t, 0));
        map.insert(seed_id("assignments", &format!("{t}_assign2")), (t, 1));
    }
    map
}

/// Generate all assessment submissions with deterministic, tiered answers.
pub fn generate_assessment_submissions(
    ctx: &SeedContext,
    assessments: &[AssessmentSpec],
    students: &[UserSpec],
    enrollments: &[EnrollmentSpec],
    answers: &HashMap<String, TermAnswers>,
) -> Vec<AssessmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(360);

    let student_indices: HashMap<Uuid, usize> = students
        .iter()
        .enumerate()
        .filter(|(_, s)| s.role == "student")
        .map(|(idx, s)| (s.id, idx))
        .collect();

    let mut class_students: HashMap<Uuid, Vec<Uuid>> = HashMap::new();
    for enrollment in enrollments {
        if student_indices.contains_key(&enrollment.user_id) {
            class_students
                .entry(enrollment.class_id)
                .or_default()
                .push(enrollment.user_id);
        }
    }

    let aq_map = assessment_term_map();
    let started_base = ctx.days_ago(10);

    for (assess_idx, assessment) in assessments.iter().enumerate() {
        if assessment.deleted_at.is_some() {
            continue;
        }

        let enrolled = class_students
            .get(&assessment.class_id)
            .cloned()
            .unwrap_or_default();
        let term_key = aq_map.get(&assessment.id).copied();

        // Identify essay questions for answer bank lookup
        let essay_q_indices: Vec<usize> = assessment
            .questions
            .iter()
            .enumerate()
            .filter(|(_, q)| q.question_type == "essay")
            .map(|(i, _)| i)
            .collect();

        for student_id in &enrolled {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };
            let tier = student_tier(global_student_idx);

            let started_at =
                started_base + chrono::Duration::minutes((global_student_idx * 5) as i64);
            let submitted_at =
                Some(started_at + chrono::Duration::minutes(15 + (global_student_idx % 30) as i64));

            let mut answers_vec = Vec::with_capacity(assessment.questions.len());
            let mut total_points: f64 = 0.0;

            for (q_idx, question) in assessment.questions.iter().enumerate() {
                let correct = is_correct(tier, global_student_idx, assess_idx, q_idx);

                let (choice_ids, text, is_correct_val, points) =
                    match question.question_type.as_str() {
                        "multiple_choice" => {
                            let choice = if correct {
                                question
                                    .choices
                                    .iter()
                                    .find(|c| c.is_correct)
                                    .or_else(|| question.choices.first())
                            } else {
                                let wrong: Vec<_> =
                                    question.choices.iter().filter(|c| !c.is_correct).collect();
                                let wrong_idx =
                                    (global_student_idx + assess_idx + q_idx) % wrong.len().max(1);
                                wrong.get(wrong_idx).copied()
                            };
                            let cids = choice.map(|c| vec![c.id]).unwrap_or_default();
                            let pts = if correct { question.points as f64 } else { 0.0 };
                            (cids, None, Some(correct), pts)
                        }
                        "identification" => {
                            let txt = if correct {
                                question
                                    .answer_key
                                    .acceptable_answers
                                    .first()
                                    .cloned()
                                    .unwrap_or_default()
                            } else {
                                format!("Incorrect answer for question {}", q_idx + 1)
                            };
                            let pts = if correct { question.points as f64 } else { 0.0 };
                            (vec![], Some(txt), Some(correct), pts)
                        }
                        "essay" => {
                            // Map essay question index to answer bank field
                            let essay_num = essay_q_indices
                                .iter()
                                .position(|&i| i == q_idx)
                                .unwrap_or(0);
                            let answer_text =
                                if let Some(t_answers) = term_key.and_then(|tk| answers.get(tk)) {
                                    match essay_num {
                                        0 => t_answers.exam_essay_1[tier].clone(),
                                        1 => t_answers.exam_essay_2[tier].clone(),
                                        _ => "Essay answer".into(),
                                    }
                                } else {
                                    "Essay answer".into()
                                };
                            let pts = essay_points(tier, question.points);
                            (vec![], Some(answer_text), None, pts)
                        }
                        _ => (vec![], None, None, 0.0),
                    };

                total_points += points;
                answers_vec.push(SubmissionAnswerSpec {
                    question_id: question.id,
                    choice_ids,
                    text,
                    is_correct: is_correct_val,
                    points,
                });
            }

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
                answers: answers_vec,
            });
        }
    }

    submissions
}

/// Generate all assignment submissions with tiered answers and grades.
pub fn generate_assignment_submissions(
    ctx: &SeedContext,
    assignments: &[AssignmentSpec],
    students: &[UserSpec],
    teachers: &[UserSpec],
    enrollments: &[EnrollmentSpec],
    answers: &HashMap<String, TermAnswers>,
) -> Vec<AssignmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(240);

    let student_indices: HashMap<Uuid, usize> = students
        .iter()
        .enumerate()
        .filter(|(_, s)| s.role == "student")
        .map(|(idx, s)| (s.id, idx))
        .collect();

    let mut class_students: HashMap<Uuid, Vec<Uuid>> = HashMap::new();
    for enrollment in enrollments {
        if student_indices.contains_key(&enrollment.user_id) {
            class_students
                .entry(enrollment.class_id)
                .or_default()
                .push(enrollment.user_id);
        }
    }

    let asq_map = assignment_term_map();
    let submitted_at_base = ctx.days_ago(4);
    let teacher_id = teachers.first().map(|t| t.id);

    for (assign_idx, assignment) in assignments.iter().enumerate() {
        if assignment.deleted_at.is_some() {
            continue;
        }

        let enrolled = class_students
            .get(&assignment.class_id)
            .cloned()
            .unwrap_or_default();
        let term_info = asq_map.get(&assignment.id).copied();

        for student_id in &enrolled {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };
            let tier = student_tier(global_student_idx);

            let submitted_at =
                submitted_at_base + chrono::Duration::hours((global_student_idx % 24) as i64);
            let points = assignment_points(tier, assignment.total_points);
            let feedback = assignment_feedback(tier);

            let text = if let Some((t_key, assign_num)) = term_info {
                answers
                    .get(t_key)
                    .map(|qa| match assign_num {
                        0 => qa.assignment_1[tier].clone(),
                        1 => qa.assignment_2[tier].clone(),
                        _ => "Assignment submission.".into(),
                    })
                    .unwrap_or_else(|| "Assignment submission.".into())
            } else {
                "Assignment submission.".into()
            };

            let sub_id = seed_id(
                "assignment_submissions",
                &format!("assign_{}_student_{}", assign_idx, global_student_idx),
            );

            submissions.push(AssignmentSubmissionSpec {
                id: sub_id,
                assignment_id: assignment.id,
                student_id: *student_id,
                text: Some(text),
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
