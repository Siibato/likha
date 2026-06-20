//! Realistic seeding fixtures with Filipino names and Grade 9 English/Science content.
//! Organized by quarter for maintainability.

pub mod common;
pub mod q1;
pub mod q2;
pub mod q3;
pub mod q4;

use uuid::Uuid;
use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::shared::*;

// ─── Class ID helpers ────────────────────────────────────────────────────────
pub fn cid(key: &str) -> Uuid { class_id(key) }
pub fn uid(name: &str) -> Uuid { user_id(name) }
pub fn tid(key: &str) -> Uuid { tos_id(key) }
pub fn compid(key: &str) -> Uuid { competency_id(key) }
pub fn aid(key: &str) -> Uuid { assessment_id(key) }
pub fn qid(a: &str, n: u32) -> Uuid { question_id(a, n) }
pub fn chid(q: &str, n: u32) -> Uuid { choice_id(q, n) }
pub fn asid(key: &str) -> Uuid { assignment_id(key) }
pub fn mid(key: &str) -> Uuid { material_id(key) }

// ─── Helpers ─────────────────────────────────────────────────────────────────
pub fn mc_choices(q_key: &str, correct_idx: usize) -> Vec<ChoiceSpec> {
    let texts = ["Option A", "Option B", "Option C", "Option D"];
    texts.iter().enumerate().map(|(i, t)| ChoiceSpec {
        id: chid(q_key, i as u32), text: (*t).into(),
        is_correct: i == correct_idx, order: i as i32,
    }).collect()
}

pub fn realistic_mc_choices(q_key: &str, texts: &[&str], correct_idx: usize) -> Vec<ChoiceSpec> {
    texts.iter().enumerate().map(|(i, t)| ChoiceSpec {
        id: chid(q_key, i as u32), text: (*t).into(),
        is_correct: i == correct_idx, order: i as i32,
    }).collect()
}

pub fn build_questions_from_bank(
    prefix: &str,
    mcqs: &[(&str, &[&str], usize, &str, &str)],
    ids: &[(&str, &str, &str, &str)],
    essays: &[(&str, i32, &str, &str)],
    comps: &[Uuid],
) -> Vec<QuestionSpec> {
    let mut qs = Vec::new();
    let mut idx = 0;
    for (text, choices, correct, diff, cog) in mcqs {
        let q_key = format!("{prefix}_q{idx}");
        let comp = comps[idx % comps.len()];
        qs.push(QuestionSpec {
            id: qid(prefix, idx as u32),
            question_type: "multiple_choice".into(),
            text: (*text).into(),
            points: 1,
            order: idx as i32,
            is_multi_select: false,
            tos_competency_id: Some(comp),
            difficulty: Some((*diff).into()),
            cognitive_level: Some((*cog).into()),
            choices: realistic_mc_choices(&q_key, choices, *correct),
            answer_key: AnswerKeySpec {
                acceptable_answers: if *correct < choices.len() { vec![choices[*correct].into()] } else { vec![] }
            },
        });
        idx += 1;
    }
    for (text, answer, diff, cog) in ids {
        let comp = comps[idx % comps.len()];
        qs.push(QuestionSpec {
            id: qid(prefix, idx as u32),
            question_type: "identification".into(),
            text: (*text).into(),
            points: 1,
            order: idx as i32,
            is_multi_select: false,
            tos_competency_id: Some(comp),
            difficulty: Some((*diff).into()),
            cognitive_level: Some((*cog).into()),
            choices: vec![],
            answer_key: AnswerKeySpec { acceptable_answers: vec![(*answer).into()] },
        });
        idx += 1;
    }
    for (text, pts, diff, cog) in essays {
        let comp = comps[idx % comps.len()];
        qs.push(QuestionSpec {
            id: qid(prefix, idx as u32),
            question_type: "essay".into(),
            text: (*text).into(),
            points: *pts,
            order: idx as i32,
            is_multi_select: false,
            tos_competency_id: Some(comp),
            difficulty: Some((*diff).into()),
            cognitive_level: Some((*cog).into()),
            choices: vec![],
            answer_key: AnswerKeySpec { acceptable_answers: vec![] },
        });
        idx += 1;
    }
    qs
}

// ─── Top-level aggregators ───────────────────────────────────────────────────
pub fn realistic_users(ctx: &SeedContext) -> Vec<UserSpec> {
    common::realistic_users(ctx)
}

pub fn realistic_school_details(ctx: &SeedContext) -> SchoolDetailsSpec {
    common::realistic_school_details(ctx)
}

pub fn realistic_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    common::realistic_classes(ctx)
}

pub fn realistic_enrollments() -> Vec<EnrollmentSpec> {
    common::realistic_enrollments()
}

pub fn realistic_learner_details() -> Vec<LearnerDetailsSpec> {
    common::realistic_learner_details()
}

pub fn realistic_tos() -> Vec<TosSpec> {
    common::realistic_tos()
}

pub fn realistic_competencies() -> Vec<CompetencySpec> {
    common::realistic_competencies()
}

pub fn realistic_materials(ctx: &SeedContext) -> Vec<MaterialSpec> {
    common::realistic_materials(ctx)
}

pub fn realistic_assessments(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let mut assessments = Vec::new();
    assessments.extend(q1::assessments::realistic_assessments_q1(ctx));
    assessments.extend(q2::assessments::realistic_assessments_q2(ctx));
    assessments.extend(q3::assessments::realistic_assessments_q3(ctx));
    assessments.extend(q4::assessments::realistic_assessments_q4(ctx));
    assessments
}

pub fn realistic_assignments(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let mut assignments = Vec::new();
    assignments.extend(q1::assignments::realistic_assignments_q1(ctx));
    assignments.extend(q2::assignments::realistic_assignments_q2(ctx));
    assignments.extend(q3::assignments::realistic_assignments_q3(ctx));
    assignments.extend(q4::assignments::realistic_assignments_q4(ctx));
    assignments
}
