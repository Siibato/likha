//! Demo seeding fixtures for focused demonstration dataset.
//!
//! 1 teacher + 30 students, 2 classes (Science 10 + Advisory 10),
//! 4 quarters of complete assessments, assignments, and learning modules.

pub mod q1;
pub mod q2;
pub mod q3;
pub mod q4;
pub mod base;

use uuid::Uuid;
use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use crate::seed::tools::seed_id;

// ─── Demo ID helpers ───────────────────────────────────────────────────────

pub fn cid(key: &str) -> Uuid { seed_id("classes", key) }
pub fn uid(name: &str) -> Uuid { seed_id("users", name) }
pub fn tid(key: &str) -> Uuid { seed_id("tos", key) }
pub fn compid(key: &str) -> Uuid { seed_id("competencies", key) }
pub fn aid(key: &str) -> Uuid { seed_id("assessments", key) }
pub fn qid(prefix: &str, n: u32) -> Uuid { seed_id("questions", &format!("{prefix}_q{n}")) }
pub fn chid(q_key: &str, n: u32) -> Uuid { seed_id("choices", &format!("{q_key}_c{n}")) }
pub fn asid(key: &str) -> Uuid { seed_id("assignments", key) }
pub fn mid(key: &str) -> Uuid { seed_id("materials", key) }

// ─── Choice / Question helpers ─────────────────────────────────────────────

pub fn mc_choices(q_key: &str, texts: &[&str], correct_idx: usize) -> Vec<ChoiceSpec> {
    texts.iter().enumerate().map(|(i, t)| ChoiceSpec {
        id: chid(q_key, i as u32),
        text: (*t).into(),
        is_correct: i == correct_idx,
        order: i as i32,
    }).collect()
}

pub fn build_questions(
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
            choices: mc_choices(&q_key, choices, *correct),
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

// ─── QuarterAnswers ────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct QuarterAnswers {
    pub exam_essay_1: [String; 4],
    pub exam_essay_2: [String; 4],
    pub assignment_1: [String; 4],
    pub assignment_2: [String; 4],
}

// ─── Aggregators ───────────────────────────────────────────────────────────

pub fn demo_users(ctx: &SeedContext) -> Vec<UserSpec> {
    base::users::demo_users(ctx)
}

pub fn demo_school_details(ctx: &SeedContext) -> SchoolDetailsSpec {
    base::school::demo_school_details(ctx)
}

pub fn demo_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    base::classes::demo_classes(ctx)
}

pub fn demo_enrollments() -> Vec<EnrollmentSpec> {
    base::enrollments::demo_enrollments()
}

pub fn demo_learner_details() -> Vec<LearnerDetailsSpec> {
    base::learner_details::demo_learner_details()
}

pub fn demo_tos() -> Vec<TosSpec> {
    base::tos::demo_tos()
}

pub fn demo_competencies() -> Vec<CompetencySpec> {
    base::competencies::demo_competencies()
}

pub fn demo_materials(ctx: &SeedContext) -> Vec<MaterialSpec> {
    let mut materials = Vec::new();
    materials.extend(q1::materials::demo_materials_q1(ctx));
    materials.extend(q2::materials::demo_materials_q2(ctx));
    materials.extend(q3::materials::demo_materials_q3(ctx));
    materials.extend(q4::materials::demo_materials_q4(ctx));
    materials
}

pub fn demo_assessments(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let mut assessments = Vec::new();
    assessments.extend(q1::assessments::demo_assessments_q1(ctx));
    assessments.extend(q2::assessments::demo_assessments_q2(ctx));
    assessments.extend(q3::assessments::demo_assessments_q3(ctx));
    assessments.extend(q4::assessments::demo_assessments_q4(ctx));
    assessments
}

pub fn demo_assignments(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let mut assignments = Vec::new();
    assignments.extend(q1::assignments::demo_assignments_q1(ctx));
    assignments.extend(q2::assignments::demo_assignments_q2(ctx));
    assignments.extend(q3::assignments::demo_assignments_q3(ctx));
    assignments.extend(q4::assignments::demo_assignments_q4(ctx));
    assignments
}

pub fn demo_answers() -> std::collections::HashMap<String, QuarterAnswers> {
    let mut map = std::collections::HashMap::new();
    map.insert("q1".into(), q1::answers::demo_answers_q1());
    map.insert("q2".into(), q2::answers::demo_answers_q2());
    map.insert("q3".into(), q3::answers::demo_answers_q3());
    map.insert("q4".into(), q4::answers::demo_answers_q4());
    map
}
