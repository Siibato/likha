//! Demo-2 submission generators with tiered, subject-aware answers.

use std::collections::HashMap;
use uuid::Uuid;

use crate::seed::fixtures::demo2::SubjectTermAnswers;
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

/// Build a map from assessment ID to (subject, term) key.
/// Demo-2 uses subject-prefixed IDs like "sci_t1_quiz1", "eng_t2_exam", etc.
fn assessment_subject_term_map() -> HashMap<Uuid, (&'static str, &'static str)> {
    let mut map = HashMap::new();
    let subjects = ["sci", "eng", "math", "ap", "fil", "tle"];
    let terms = ["t1", "t2", "t3"];
    let assessments = ["quiz1", "quiz2", "exam"];
    
    for subject in subjects {
        for term in terms {
            for assess in assessments {
                let id = seed_id("assessments", &format!("{subject}_{term}_{assess}"));
                map.insert(id, (subject, term));
            }
        }
    }
    map
}

/// Build a map from assignment ID to (subject, term, assignment number).
fn assignment_subject_term_map() -> HashMap<Uuid, (&'static str, &'static str, usize)> {
    let mut map = HashMap::new();
    let subjects = ["sci", "eng", "math", "ap", "fil", "tle"];
    let terms = ["t1", "t2", "t3"];
    
    for subject in subjects {
        for term in terms {
            for assign_num in 0..2 {
                let id = seed_id("assignments", &format!("{subject}_{term}_assign{}", assign_num + 1));
                map.insert(id, (subject, term, assign_num));
            }
        }
    }
    map
}

/// Generate all assessment submissions with deterministic, tiered answers.
pub fn generate_demo2_assessment_submissions(
    ctx: &SeedContext,
    assessments: &[AssessmentSpec],
    students: &[UserSpec],
    enrollments: &[EnrollmentSpec],
    answers: &HashMap<(&'static str, &'static str), SubjectTermAnswers>,
) -> Vec<AssessmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(540); // 18 assessments × 30 students

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

    let ast_map = assessment_subject_term_map();
    let started_base = ctx.days_ago(10);

    for (assess_idx, assessment) in assessments.iter().enumerate() {
        if assessment.deleted_at.is_some() {
            continue;
        }

        let enrolled = class_students
            .get(&assessment.class_id)
            .cloned()
            .unwrap_or_default();
        let subject_term = ast_map.get(&assessment.id).copied();

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
                                if let Some((subject, term)) = subject_term {
                                    answers
                                        .get(&(subject, term))
                                        .and_then(|sa| {
                                            match essay_num {
                                                0 => sa.exam_essays.get(0).map(|e| e[tier].clone()),
                                                1 => sa.exam_essays.get(1).map(|e| e[tier].clone()),
                                                _ => None,
                                            }
                                        })
                                        .unwrap_or_else(|| "Essay answer".into())
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
pub fn generate_demo2_assignment_submissions(
    ctx: &SeedContext,
    assignments: &[AssignmentSpec],
    students: &[UserSpec],
    teachers: &[UserSpec],
    enrollments: &[EnrollmentSpec],
    answers: &HashMap<(&'static str, &'static str), SubjectTermAnswers>,
) -> Vec<AssignmentSubmissionSpec> {
    let mut submissions = Vec::with_capacity(360); // 12 assignments × 30 students

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

    let asq_map = assignment_subject_term_map();
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
        let subject_term_assign = asq_map.get(&assignment.id).copied();

        for student_id in &enrolled {
            let Some(&global_student_idx) = student_indices.get(student_id) else {
                continue;
            };
            let tier = student_tier(global_student_idx);

            let submitted_at =
                submitted_at_base + chrono::Duration::hours((global_student_idx % 24) as i64);
            let points = assignment_points(tier, assignment.total_points);
            let feedback = assignment_feedback(tier);

            let text = if let Some((subject, term, assign_num)) = subject_term_assign {
                answers
                    .get(&(subject, term))
                    .and_then(|sa| {
                        sa.assignments.get(assign_num).map(|a| a[tier].clone())
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
