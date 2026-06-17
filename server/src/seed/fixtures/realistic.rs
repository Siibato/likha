//! Realistic seeding fixtures with Filipino names and Grade 9 English/Science content.

use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

use super::shared::*;

// ─── Class ID helpers ────────────────────────────────────────────────────────
fn cid(key: &str) -> Uuid { class_id(key) }
fn uid(name: &str) -> Uuid { user_id(name) }
fn tid(key: &str) -> Uuid { tos_id(key) }
fn compid(key: &str) -> Uuid { competency_id(key) }
fn aid(key: &str) -> Uuid { assessment_id(key) }
fn qid(a: &str, n: u32) -> Uuid { question_id(a, n) }
fn chid(q: &str, n: u32) -> Uuid { choice_id(q, n) }
fn asid(key: &str) -> Uuid { assignment_id(key) }
fn mid(key: &str) -> Uuid { material_id(key) }

// ─── Names ───────────────────────────────────────────────────────────────────
const STUDENT_DATA: [(&str, &str); 30] = [
    ("juan.delacruz", "Juan Dela Cruz"),
    ("maria.santos", "Maria Santos"),
    ("antonio.garcia", "Antonio Garcia"),
    ("carmen.bautista", "Carmen Bautista"),
    ("pedro.lim", "Pedro Lim"),
    ("rosa.mendoza", "Rosa Mendoza"),
    ("miguel.fernandez", "Miguel Fernandez"),
    ("lucia.tan", "Lucia Tan"),
    ("francisco.ramos", "Francisco Ramos"),
    ("teresa.villanueva", "Teresa Villanueva"),
    ("carlos.navarro", "Carlos Navarro"),
    ("dolores.castillo", "Dolores Castillo"),
    ("manuel.flores", "Manuel Flores"),
    ("esperanza.morales", "Esperanza Morales"),
    ("rafael.santiago", "Rafael Santiago"),
    ("consuelo.delrosario", "Consuelo Del Rosario"),
    ("andres.deleon", "Andres De Leon"),
    ("mercedes.reyes", "Mercedes Reyes"),
    ("gabriel.aguilar", "Gabriel Aguilar"),
    ("remedios.silva", "Remedios Silva"),
    ("diego.alvarez", "Diego Alvarez"),
    ("milagros.pascual", "Milagros Pascual"),
    ("lorenzo.gonzalez", "Lorenzo Gonzalez"),
    ("trinidad.soriano", "Trinidad Soriano"),
    ("ramon.rivera", "Ramon Rivera"),
    ("pilar.delacruz", "Pilar Dela Cruz"),
    ("ernesto.bautista", "Ernesto Bautista"),
    ("soledad.ortega", "Soledad Ortega"),
    ("eduardo.martinez", "Eduardo Martinez"),
    ("cristina.domingo", "Cristina Domingo"),
];

// ─── Users ───────────────────────────────────────────────────────────────────
pub fn realistic_users(ctx: &SeedContext) -> Vec<UserSpec> {
    let created = ctx.days_ago(30);
    let activated = ctx.days_ago(29);
    let mut users = Vec::with_capacity(33);

    // Teachers
    users.push(UserSpec {
        id: uid("maria.reyes"), username: "maria.reyes".into(),
        full_name: "Maria Elena Reyes".into(), role: "teacher".into(),
        password_hash: Some(bcrypt::hash(PASSWORD_TEACHER, 4).unwrap()),
        account_status: "active".into(), created_at: created, activated_at: Some(activated), deleted_at: None,
    });
    users.push(UserSpec {
        id: uid("jose.cruz"), username: "jose.cruz".into(),
        full_name: "Jose Antonio Cruz".into(), role: "teacher".into(),
        password_hash: Some(bcrypt::hash(PASSWORD_TEACHER, 4).unwrap()),
        account_status: "active".into(), created_at: created, activated_at: Some(activated), deleted_at: None,
    });

    // Students
    for &(uname, fname) in &STUDENT_DATA {
        users.push(UserSpec {
            id: uid(uname), username: uname.into(),
            full_name: fname.into(), role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(), created_at: created, activated_at: Some(activated), deleted_at: None,
        });
    }

    users
}

// ─── School Settings ───────────────────────────────────────────────────────────
pub fn realistic_school_settings(ctx: &SeedContext) -> SchoolSettingsSpec {
    SchoolSettingsSpec {
        id: 1,
        school_code: "LIKHA01".into(),
        school_name: Some("Likha National High School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        updated_at: ctx.now(),
    }
}

// ─── Classes ─────────────────────────────────────────────────────────────────
pub fn realistic_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    let created = ctx.days_ago(25);
    vec![
        ClassSpec {
            id: cid("english_9a"), title: "English 9".into(),
            description: Some("Grade 9 English class".into()), grade_level: Some("9".into()),
            school_year: Some("2025-2026".into()), is_advisory: false, is_archived: false,
            created_at: created, deleted_at: None,
        },
        ClassSpec {
            id: cid("science_9a"), title: "Science 9".into(),
            description: Some("Grade 9 Science class".into()), grade_level: Some("9".into()),
            school_year: Some("2025-2026".into()), is_advisory: false, is_archived: false,
            created_at: created, deleted_at: None,
        },
        ClassSpec {
            id: cid("advisory_9a"), title: "Advisory 9-A".into(),
            description: Some("Grade 9 Advisory class".into()), grade_level: Some("9".into()),
            school_year: Some("2025-2026".into()), is_advisory: true, is_archived: false,
            created_at: created, deleted_at: None,
        },
    ]
}

// ─── Enrollments ─────────────────────────────────────────────────────────────
pub fn realistic_enrollments() -> Vec<EnrollmentSpec> {
    let mut enrollments = Vec::with_capacity(93);

    // Teacher enrollments
    enrollments.push(EnrollmentSpec { class_id: cid("english_9a"), user_id: uid("maria.reyes") });
    enrollments.push(EnrollmentSpec { class_id: cid("science_9a"), user_id: uid("jose.cruz") });
    enrollments.push(EnrollmentSpec { class_id: cid("advisory_9a"), user_id: uid("maria.reyes") });

    // All 30 students in all 3 classes
    for &(uname, _) in &STUDENT_DATA {
        let sid = uid(uname);
        enrollments.push(EnrollmentSpec { class_id: cid("english_9a"), user_id: sid });
        enrollments.push(EnrollmentSpec { class_id: cid("science_9a"), user_id: sid });
        enrollments.push(EnrollmentSpec { class_id: cid("advisory_9a"), user_id: sid });
    }

    enrollments
}

// ─── TOS ─────────────────────────────────────────────────────────────────────
pub fn realistic_tos() -> Vec<TosSpec> {
    vec![
        TosSpec {
            id: tid("english_9a_tos"), class_id: cid("english_9a"), period: 1,
            title: "TOS for English 9 - Q1".into(), template_type: "difficulty".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("science_9a_tos"), class_id: cid("science_9a"), period: 1,
            title: "TOS for Science 9 - Q1".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("advisory_9a_tos"), class_id: cid("advisory_9a"), period: 1,
            title: "TOS for Advisory 9-A - Q1".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
    ]
}

// ─── Competencies ────────────────────────────────────────────────────────────
pub fn realistic_competencies() -> Vec<CompetencySpec> {
    vec![
        // English 9
        CompetencySpec { id: compid("e9_comp_0"), tos_id: tid("english_9a_tos"), code: Some("E9PL-Ia-1".into()), text: "Listen to get information from oral texts".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("e9_comp_1"), tos_id: tid("english_9a_tos"), code: Some("E9RC-Ib-2".into()), text: "Identify text types (narrative, expository, persuasive)".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("e9_comp_2"), tos_id: tid("english_9a_tos"), code: Some("E9LT-Ic-3".into()), text: "Explain literary devices used in Afro-Asian literature".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("e9_comp_3"), tos_id: tid("english_9a_tos"), code: Some("E9WC-Id-4".into()), text: "Write a persuasive essay with clear arguments".into(), time_units_taught: 5, order: 3 },
        // Science 9
        CompetencySpec { id: compid("s9_comp_0"), tos_id: tid("science_9a_tos"), code: Some("S9ES-Ia-1".into()), text: "Describe the internal structure of the Earth".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s9_comp_1"), tos_id: tid("science_9a_tos"), code: Some("S9ES-Ib-2".into()), text: "Explain the theory of plate tectonics".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s9_comp_2"), tos_id: tid("science_9a_tos"), code: Some("S9LT-Ic-3".into()), text: "Describe how genetic information is passed from parents to offspring".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s9_comp_3"), tos_id: tid("science_9a_tos"), code: Some("S9MT-Id-4".into()), text: "Explain how different factors affect the rate of chemical reactions".into(), time_units_taught: 5, order: 3 },
        // Advisory 9-A
        CompetencySpec { id: compid("a9_comp_0"), tos_id: tid("advisory_9a_tos"), code: Some("AD9PH-Ia-1".into()), text: "Demonstrate positive personal health practices".into(), time_units_taught: 3, order: 0 },
        CompetencySpec { id: compid("a9_comp_1"), tos_id: tid("advisory_9a_tos"), code: Some("AD9PH-Ib-1".into()), text: "Explain the dimensions of holistic health".into(), time_units_taught: 3, order: 1 },
    ]
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
fn mc_choices(q_key: &str, correct_idx: usize) -> Vec<ChoiceSpec> {
    let texts = ["Option A", "Option B", "Option C", "Option D"];
    texts.iter().enumerate().map(|(i, t)| ChoiceSpec {
        id: chid(q_key, i as u32), text: (*t).into(),
        is_correct: i == correct_idx, order: i as i32,
    }).collect()
}

fn exam_questions(prefix: &str, count: usize, comps: &[Uuid]) -> Vec<QuestionSpec> {
    let mut qs = Vec::with_capacity(count);
    for i in 0..count {
        let q_key = format!("{prefix}_q{i}");
        let comp = comps[i % comps.len()];
        let diff = match i % 3 { 0 => "easy", 1 => "average", _ => "difficult" };
        let cog = match i % 6 {
            0 => "remembering", 1 => "understanding", 2 => "applying",
            3 => "analyzing", 4 => "evaluating", _ => "creating",
        };
        let (qtype, pts, has_choices, ans) = if i < count * 2 / 5 {
            ("multiple_choice", 1, true, vec!["A".into()])
        } else if i < count * 7 / 10 {
            ("identification", 1, false, vec![format!("ans{i}")])
        } else if i < count * 9 / 10 {
            ("enumeration", 2, false, vec![format!("a{i}"), format!("b{i}")])
        } else {
            ("essay", 5, false, vec![])
        };
        let choices = if has_choices { mc_choices(&q_key, 0) } else { vec![] };
        qs.push(QuestionSpec {
            id: qid(prefix, i as u32), question_type: qtype.into(),
            text: format!("Question {} for {}", i + 1, prefix), points: pts, order: i as i32,
            is_multi_select: false, tos_competency_id: Some(comp),
            difficulty: Some(diff.into()), cognitive_level: Some(cog.into()), choices,
            answer_key: AnswerKeySpec { acceptable_answers: ans },
        });
    }
    qs
}

// ─── Assessments ─────────────────────────────────────────────────────────────
pub fn realistic_assessments(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(20);
    let now = ctx.now();
    let mut assessments = Vec::with_capacity(9);

    // English 9 - Quiz 1 (5 items, written work)
    assessments.push(AssessmentSpec {
        id: aid("eng_quiz1"), class_id: cid("english_9a"),
        title: "Quiz 1: Afro-Asian Literature".into(),
        description: Some("5-item quiz on literary devices and Afro-Asian texts.".into()),
        time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1),
        show_results_immediately: true, total_points: 13, component: "written_work".into(),
        tos_id: tid("english_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: true, grading_period_number: 1,
        questions: vec![
            QuestionSpec { id: qid("eng_quiz1", 0), question_type: "multiple_choice".into(),
                text: "Which literary device is used in the phrase 'the wind whispered through the trees'?".into(),
                points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_2")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()),
                choices: mc_choices("eng_quiz1_q0", 2),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] }, },
            QuestionSpec { id: qid("eng_quiz1", 1), question_type: "multiple_choice".into(),
                text: "What is the main theme of the epic 'Beowulf'?".into(),
                points: 1, order: 1, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_2")),
                difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()),
                choices: mc_choices("eng_quiz1_q1", 0),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["A".into()] }, },
            QuestionSpec { id: qid("eng_quiz1", 2), question_type: "identification".into(),
                text: "What type of text provides factual information about a topic?".into(),
                points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_1")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Expository".into()] }, },
            QuestionSpec { id: qid("eng_quiz1", 3), question_type: "identification".into(),
                text: "What figure of speech compares two unlike things using 'like' or 'as'?".into(),
                points: 1, order: 3, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_2")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Simile".into()] }, },
            QuestionSpec { id: qid("eng_quiz1", 4), question_type: "essay".into(),
                text: "Explain how cultural values are reflected in Afro-Asian folk tales. Provide two examples.".into(),
                points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_2")),
                difficulty: Some("hard".into()), cognitive_level: Some("evaluating".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec![] }, },
        ],
    });

    // English 9 - Quiz 2 (5 items, performance task)
    assessments.push(AssessmentSpec {
        id: aid("eng_quiz2"), class_id: cid("english_9a"),
        title: "Quiz 2: Reading Comprehension & Writing".into(),
        description: Some("5-item quiz on reading strategies and writing skills.".into()),
        time_limit_minutes: 30, open_at: now - chrono::Duration::days(1), close_at: now + chrono::Duration::days(7),
        show_results_immediately: false, total_points: 12, component: "performance_task".into(),
        tos_id: tid("english_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: false, grading_period_number: 1,
        questions: vec![
            QuestionSpec { id: qid("eng_quiz2", 0), question_type: "multiple_choice".into(),
                text: "In persuasive writing, what is the purpose of a counterargument?".into(),
                points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_3")),
                difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()),
                choices: mc_choices("eng_quiz2_q0", 1),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into()] }, },
            QuestionSpec { id: qid("eng_quiz2", 1), question_type: "multiple_choice".into(),
                text: "Which sentence is written in passive voice?".into(),
                points: 1, order: 1, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_1")),
                difficulty: Some("medium".into()), cognitive_level: Some("analyzing".into()),
                choices: mc_choices("eng_quiz2_q1", 2),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] }, },
            QuestionSpec { id: qid("eng_quiz2", 2), question_type: "identification".into(),
                text: "What is the term for converting direct speech to indirect speech?".into(),
                points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_1")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Reported speech".into()] }, },
            QuestionSpec { id: qid("eng_quiz2", 3), question_type: "identification".into(),
                text: "Which text type tells a story with a sequence of events and characters?".into(),
                points: 1, order: 3, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_1")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Narrative".into()] }, },
            QuestionSpec { id: qid("eng_quiz2", 4), question_type: "essay".into(),
                text: "Write a short persuasive paragraph (5-7 sentences) arguing why students should read literature from other cultures.".into(),
                points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(compid("e9_comp_3")),
                difficulty: Some("hard".into()), cognitive_level: Some("creating".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec![] }, },
        ],
    });

    // English 9 - Quarter Exam (50 items)
    let eng_exam_qs = exam_questions("eng_exam", 50, &[compid("e9_comp_0"), compid("e9_comp_1"), compid("e9_comp_2"), compid("e9_comp_3")]);
    let eng_exam_points: i32 = eng_exam_qs.iter().map(|q| q.points).sum();
    assessments.push(AssessmentSpec {
        id: aid("eng_exam"), class_id: cid("english_9a"),
        title: "Quarter 1 Exam: English 9".into(),
        description: Some("50-item quarterly assessment.".into()),
        time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2),
        show_results_immediately: true, total_points: eng_exam_points, component: "quarterly_assessment".into(),
        tos_id: tid("english_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: true, grading_period_number: 1,
        questions: eng_exam_qs,
    });

    // Science 9 - Quiz 1 (5 items, written work)
    assessments.push(AssessmentSpec {
        id: aid("sci_quiz1"), class_id: cid("science_9a"),
        title: "Quiz 1: Earth's Structure & Plate Tectonics".into(),
        description: Some("5-item quiz on Earth's layers and plate tectonics.".into()),
        time_limit_minutes: 30, open_at: now - chrono::Duration::days(8), close_at: now - chrono::Duration::days(2),
        show_results_immediately: true, total_points: 11, component: "written_work".into(),
        tos_id: tid("science_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: true, grading_period_number: 1,
        questions: vec![
            QuestionSpec { id: qid("sci_quiz1", 0), question_type: "multiple_choice".into(),
                text: "Which layer of the Earth is composed primarily of iron and nickel?".into(),
                points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_0")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()),
                choices: mc_choices("sci_quiz1_q0", 3),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["D".into()] }, },
            QuestionSpec { id: qid("sci_quiz1", 1), question_type: "multiple_choice".into(),
                text: "What type of boundary occurs when two plates move away from each other?".into(),
                points: 1, order: 1, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_1")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()),
                choices: mc_choices("sci_quiz1_q1", 1),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into()] }, },
            QuestionSpec { id: qid("sci_quiz1", 2), question_type: "identification".into(),
                text: "What instrument is used to measure seismic waves?".into(),
                points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_1")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Seismograph".into()] }, },
            QuestionSpec { id: qid("sci_quiz1", 3), question_type: "identification".into(),
                text: "Which landform is created by the collision of two continental plates?".into(),
                points: 1, order: 3, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_1")),
                difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Mountain range".into()] }, },
            QuestionSpec { id: qid("sci_quiz1", 4), question_type: "essay".into(),
                text: "Explain how the theory of plate tectonics explains the occurrence of earthquakes in the Philippines.".into(),
                points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_1")),
                difficulty: Some("hard".into()), cognitive_level: Some("evaluating".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec![] }, },
        ],
    });

    // Science 9 - Quiz 2 (5 items, performance task)
    assessments.push(AssessmentSpec {
        id: aid("sci_quiz2"), class_id: cid("science_9a"),
        title: "Quiz 2: Genetics & Chemical Reactions".into(),
        description: Some("5-item quiz on genetics and chemical reactions.".into()),
        time_limit_minutes: 30, open_at: now - chrono::Duration::days(1), close_at: now + chrono::Duration::days(7),
        show_results_immediately: false, total_points: 12, component: "performance_task".into(),
        tos_id: tid("science_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: false, grading_period_number: 1,
        questions: vec![
            QuestionSpec { id: qid("sci_quiz2", 0), question_type: "multiple_choice".into(),
                text: "What is the basic unit of heredity passed from parents to offspring?".into(),
                points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_2")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()),
                choices: mc_choices("sci_quiz2_q0", 2),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] }, },
            QuestionSpec { id: qid("sci_quiz2", 1), question_type: "multiple_choice".into(),
                text: "Which factor increases the rate of a chemical reaction by providing an alternative pathway?".into(),
                points: 1, order: 1, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_3")),
                difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()),
                choices: mc_choices("sci_quiz2_q1", 3),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["D".into()] }, },
            QuestionSpec { id: qid("sci_quiz2", 2), question_type: "identification".into(),
                text: "What is the process by which a cell divides into two identical daughter cells?".into(),
                points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_2")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Mitosis".into()] }, },
            QuestionSpec { id: qid("sci_quiz2", 3), question_type: "identification".into(),
                text: "What molecule carries genetic information in most living organisms?".into(),
                points: 1, order: 3, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_2")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["DNA".into()] }, },
            QuestionSpec { id: qid("sci_quiz2", 4), question_type: "essay".into(),
                text: "Describe how Mendel's experiments with pea plants led to the understanding of dominant and recessive traits.".into(),
                points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(compid("s9_comp_2")),
                difficulty: Some("hard".into()), cognitive_level: Some("analyzing".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec![] }, },
        ],
    });

    // Science 9 - Quarter Exam (50 items)
    let sci_exam_qs = exam_questions("sci_exam", 50, &[compid("s9_comp_0"), compid("s9_comp_1"), compid("s9_comp_2"), compid("s9_comp_3")]);
    let sci_exam_points: i32 = sci_exam_qs.iter().map(|q| q.points).sum();
    assessments.push(AssessmentSpec {
        id: aid("sci_exam"), class_id: cid("science_9a"),
        title: "Quarter 1 Exam: Science 9".into(),
        description: Some("50-item quarterly assessment.".into()),
        time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2),
        show_results_immediately: true, total_points: sci_exam_points, component: "quarterly_assessment".into(),
        tos_id: tid("science_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: true, grading_period_number: 1,
        questions: sci_exam_qs,
    });

    // Advisory 9-A - Quiz (5 items, written work)
    assessments.push(AssessmentSpec {
        id: aid("adv_quiz1"), class_id: cid("advisory_9a"),
        title: "Quiz: Health and Wellness".into(),
        description: Some("5-item quiz on holistic health.".into()),
        time_limit_minutes: 20, open_at: now - chrono::Duration::days(5), close_at: now + chrono::Duration::days(2),
        show_results_immediately: true, total_points: 10, component: "written_work".into(),
        tos_id: tid("advisory_9a_tos"), created_at: created, deleted_at: None,
        is_published: true, results_released: true, grading_period_number: 1,
        questions: vec![
            QuestionSpec { id: qid("adv_quiz1", 0), question_type: "multiple_choice".into(),
                text: "Which dimension of holistic health refers to the ability to share feelings with others?".into(),
                points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(compid("a9_comp_1")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()),
                choices: mc_choices("adv_quiz1_q0", 2),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] }, },
            QuestionSpec { id: qid("adv_quiz1", 1), question_type: "multiple_choice".into(),
                text: "What is the recommended amount of sleep for adolescents?".into(),
                points: 1, order: 1, is_multi_select: false, tos_competency_id: Some(compid("a9_comp_0")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()),
                choices: mc_choices("adv_quiz1_q1", 1),
                answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into()] }, },
            QuestionSpec { id: qid("adv_quiz1", 2), question_type: "identification".into(),
                text: "What term describes the ability to bounce back from difficulties?".into(),
                points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(compid("a9_comp_0")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Resilience".into()] }, },
            QuestionSpec { id: qid("adv_quiz1", 3), question_type: "identification".into(),
                text: "Which food group should make up the largest portion of a balanced meal?".into(),
                points: 1, order: 3, is_multi_select: false, tos_competency_id: Some(compid("a9_comp_0")),
                difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec!["Grains".into(), "Go foods".into()] }, },
            QuestionSpec { id: qid("adv_quiz1", 4), question_type: "essay".into(),
                text: "Describe two ways you can maintain emotional wellness during stressful school periods.".into(),
                points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(compid("a9_comp_0")),
                difficulty: Some("hard".into()), cognitive_level: Some("applying".into()), choices: vec![],
                answer_key: AnswerKeySpec { acceptable_answers: vec![] }, },
        ],
    });

    assessments
}

// ─── Assignments ─────────────────────────────────────────────────────────────
pub fn realistic_assignments(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("eng_assign1"), class_id: cid("english_9a"),
            title: "Persuasive Essay: Importance of Reading Literature".into(),
            instructions: "Write a 3-paragraph persuasive essay (150-200 words) arguing why students should read literature from African and Asian cultures. Include at least one specific example of a text we discussed in class.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(5), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("eng_assign2"), class_id: cid("english_9a"),
            title: "Character Analysis: Describe a Hero from an Afro-Asian Epic".into(),
            instructions: "Choose one hero from an Afro-Asian epic we studied (e.g., Beowulf, Gilgamesh, or Biag ni Lam-ang). Write a 200-word analysis describing three heroic qualities and provide evidence from the text.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now + chrono::Duration::days(2), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("sci_assign1"), class_id: cid("science_9a"),
            title: "Lab Report: Observing Chemical Reactions".into(),
            instructions: "Write a formal lab report describing the chemical reaction observed in the class demonstration. Include: (1) Objective, (2) Materials used, (3) Procedure, (4) Observations, (5) Conclusion with the balanced chemical equation.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(3), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("sci_assign2"), class_id: cid("science_9a"),
            title: "Research Summary: Plate Tectonics in the Philippines".into(),
            instructions: "Research one major Philippine fault line or volcanic area. Write a 200-word summary explaining its geological cause (using plate tectonics theory), its location, and its potential impact on nearby communities.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now + chrono::Duration::days(5), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("adv_assign1"), class_id: cid("advisory_9a"),
            title: "Reflection: My Holistic Health Plan".into(),
            instructions: "Reflect on your current health habits across the six dimensions of holistic health. Identify one strength and one area for improvement. Write a 150-word action plan for improving your chosen area.".into(),
            total_points: 30, allows_text_submission: true, allows_file_submission: false,
            due_at: now + chrono::Duration::days(7), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
    ]
}

// ─── Materials ───────────────────────────────────────────────────────────────
pub fn realistic_materials(ctx: &SeedContext) -> Vec<MaterialSpec> {
    vec![
        MaterialSpec {
            id: mid("eng_mod1"), class_id: cid("english_9a"),
            title: "Module 1: Introduction to Afro-Asian Literature".into(),
            description: Some("Overview of oral traditions, epics, myths, and legends from Africa and Asia.".into()),
            content_text: Some("This module explores the rich literary traditions of Africa and Asia. Students will study epics such as Beowulf, Gilgamesh, and Biag ni Lam-ang, identifying common themes like heroism, good versus evil, and cultural values.".into()),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("eng_mod2"), class_id: cid("english_9a"),
            title: "Module 2: Reading Strategies and Text Types".into(),
            description: Some("How to identify narrative, expository, and persuasive texts.".into()),
            content_text: Some("Learn to distinguish between narrative, expository, and persuasive texts. Practice skimming and scanning techniques to locate main ideas and supporting details. Recognize literary devices including simile, metaphor, personification, and hyperbole.".into()),
            order_index: 1, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("sci_mod1"), class_id: cid("science_9a"),
            title: "Module 1: The Earth's Interior and Plate Tectonics".into(),
            description: Some("Structure of the Earth and theory of plate tectonics.".into()),
            content_text: Some("This module covers the structure of the Earth (crust, mantle, outer core, inner core), the theory of plate tectonics, types of plate boundaries (divergent, convergent, transform), and landforms created by plate movement. Special focus on earthquakes and volcanoes in the Philippines.".into()),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("sci_mod2"), class_id: cid("science_9a"),
            title: "Module 2: Genetics and Heredity".into(),
            description: Some("DNA, genes, chromosomes, and Mendel's laws of inheritance.".into()),
            content_text: Some("Explore DNA structure and function, genes and chromosomes, Mendel's laws of inheritance, dominant and recessive traits, mitosis versus meiosis, genetic variation and mutation.".into()),
            order_index: 1, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("adv_mod1"), class_id: cid("advisory_9a"),
            title: "Module 1: Understanding Holistic Health".into(),
            description: Some("Six dimensions of health and self-assessment tools.".into()),
            content_text: Some("Learn the six dimensions of health (physical, emotional, social, mental, spiritual, environmental). Use self-assessment tools to evaluate your current wellness and practice goal-setting for personal wellness.".into()),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("adv_mod2"), class_id: cid("advisory_9a"),
            title: "Module 2: Building Resilience and Positive Relationships".into(),
            description: Some("Coping strategies for stress and communication skills.".into()),
            content_text: Some("Develop coping strategies for stress, improve communication skills, build supportive friendships, and learn to recognize when to seek help from trusted adults or counselors.".into()),
            order_index: 1, created_at: ctx.now(),
        },
    ]
}
