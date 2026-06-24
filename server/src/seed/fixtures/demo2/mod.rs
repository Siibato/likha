//! Demo-2 seeding fixtures for full single-class demonstration dataset.
//!
//! 6 teachers + 30 students, 7 classes (1 Advisory + 6 subjects),
//! 3 terms of complete assessments, assignments, and learning modules.

pub mod base;
pub mod t1;
pub mod t2;
pub mod t3;

use crate::seed::specs::*;
use crate::seed::tools::seed_id;
use crate::seed::tools::SeedContext;
use uuid::Uuid;

// ─── Demo-2 ID helpers (subject-prefixed to avoid collisions) ───────────────

pub fn cid(key: &str) -> Uuid {
    seed_id("classes", key)
}
pub fn uid(name: &str) -> Uuid {
    seed_id("users", name)
}
pub fn tid(key: &str) -> Uuid {
    seed_id("tos", key)
}
pub fn compid(key: &str) -> Uuid {
    seed_id("competencies", key)
}
pub fn aid(key: &str) -> Uuid {
    seed_id("assessments", key)
}
pub fn qid(prefix: &str, n: u32) -> Uuid {
    seed_id("questions", &format!("{prefix}_q{n}"))
}
pub fn chid(t_key: &str, n: u32) -> Uuid {
    seed_id("choices", &format!("{t_key}_c{n}"))
}
pub fn asid(key: &str) -> Uuid {
    seed_id("assignments", key)
}
pub fn mid(key: &str) -> Uuid {
    seed_id("materials", key)
}

// ─── Choice / Question helpers (reused from demo-1) ───────────────────────

pub fn mc_choices(t_key: &str, texts: &[&str], correct_idx: usize) -> Vec<ChoiceSpec> {
    texts
        .iter()
        .enumerate()
        .map(|(i, t)| ChoiceSpec {
            id: chid(t_key, i as u32),
            text: (*t).into(),
            is_correct: i == correct_idx,
            order: i as i32,
        })
        .collect()
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
        let t_key = format!("{prefix}_q{idx}");
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
            choices: mc_choices(&t_key, choices, *correct),
            answer_key: AnswerKeySpec {
                acceptable_answers: if *correct < choices.len() {
                    vec![choices[*correct].into()]
                } else {
                    vec![]
                },
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
            answer_key: AnswerKeySpec {
                acceptable_answers: vec![(*answer).into()],
            },
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
            answer_key: AnswerKeySpec {
                acceptable_answers: vec![],
            },
        });
        idx += 1;
    }
    qs
}

// ─── SubjectTermAnswers (new structure for demo-2) ───────────────────────────

#[derive(Debug, Clone)]
pub struct SubjectTermAnswers {
    /// Each essay → 4 tier variants (tier 0 = excellent, tier 3 = developing)
    pub exam_essays: Vec<[String; 4]>,
    /// Each assignment → 4 tier variants
    pub assignments: Vec<[String; 4]>,
}

// ─── Aggregators ───────────────────────────────────────────────────────────

pub fn demo2_users(ctx: &SeedContext) -> Vec<UserSpec> {
    base::users::demo2_users(ctx)
}

pub fn demo2_school_details(ctx: &SeedContext) -> SchoolDetailsSpec {
    base::school::demo2_school_details(ctx)
}

pub fn demo2_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    base::classes::demo2_classes(ctx)
}

pub fn demo2_enrollments() -> Vec<EnrollmentSpec> {
    base::enrollments::demo2_enrollments()
}

pub fn demo2_learner_details() -> Vec<LearnerDetailsSpec> {
    base::learner_details::demo2_learner_details()
}

pub fn demo2_tos() -> Vec<TosSpec> {
    base::tos::demo2_tos()
}

pub fn demo2_competencies() -> Vec<CompetencySpec> {
    base::competencies::demo2_competencies()
}

pub fn demo2_materials(ctx: &SeedContext) -> Vec<MaterialSpec> {
    let mut materials = Vec::new();
    materials.extend(t1::materials::demo2_materials_t1(ctx));
    materials.extend(t2::materials::demo2_materials_t2(ctx));
    materials.extend(t3::materials::demo2_materials_t3(ctx));
    materials
}

pub fn demo2_assessments(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let mut assessments = Vec::new();
    assessments.extend(t1::assessments::demo2_assessments_t1(ctx));
    assessments.extend(t2::assessments::demo2_assessments_t2(ctx));
    assessments.extend(t3::assessments::demo2_assessments_t3(ctx));
    assessments
}

pub fn demo2_assignments(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let mut assignments = Vec::new();
    assignments.extend(t1::assignments::demo2_assignments_t1(ctx));
    assignments.extend(t2::assignments::demo2_assignments_t2(ctx));
    assignments.extend(t3::assignments::demo2_assignments_t3(ctx));
    assignments
}

/// Answer bank keyed by "{subject}_{term}" e.g. "sci_t1", "eng_t2"
pub fn demo2_answers() -> std::collections::HashMap<String, SubjectTermAnswers> {
    let mut map = std::collections::HashMap::new();
    // Science
    map.insert("sci_t1".into(), t1::answers::demo2_answers_sci_t1());
    map.insert("sci_t2".into(), t2::answers::demo2_answers_sci_t2());
    map.insert("sci_t3".into(), t3::answers::demo2_answers_sci_t3());
    // English
    map.insert("eng_t1".into(), t1::answers::demo2_answers_eng_t1());
    map.insert("eng_t2".into(), t2::answers::demo2_answers_eng_t2());
    map.insert("eng_t3".into(), t3::answers::demo2_answers_eng_t3());
    // Math
    map.insert("math_t1".into(), t1::answers::demo2_answers_math_t1());
    map.insert("math_t2".into(), t2::answers::demo2_answers_math_t2());
    map.insert("math_t3".into(), t3::answers::demo2_answers_math_t3());
    // AP
    map.insert("ap_t1".into(), t1::answers::demo2_answers_ap_t1());
    map.insert("ap_t2".into(), t2::answers::demo2_answers_ap_t2());
    map.insert("ap_t3".into(), t3::answers::demo2_answers_ap_t3());
    // Filipino
    map.insert("fil_t1".into(), t1::answers::demo2_answers_fil_t1());
    map.insert("fil_t2".into(), t2::answers::demo2_answers_fil_t2());
    map.insert("fil_t3".into(), t3::answers::demo2_answers_fil_t3());
    // TLE
    map.insert("tle_t1".into(), t1::answers::demo2_answers_tle_t1());
    map.insert("tle_t2".into(), t2::answers::demo2_answers_tle_t2());
    map.insert("tle_t3".into(), t3::answers::demo2_answers_tle_t3());
    map
}
