//! E2E test fixtures.

use uuid::{uuid, Uuid};

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

use super::shared::*;

// ─── User IDs ────────────────────────────────────────────────────────────────
pub const ADMIN_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000001");
pub const TEACHER_01_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000002");
pub const TEACHER_02_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000003");
pub const STUDENT_01_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000010");
pub const STUDENT_02_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000011");
pub const STUDENT_03_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000012");
pub const STUDENT_DELETED_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000099");

// ─── Class IDs ───────────────────────────────────────────────────────────────
pub const CLASS_MATH_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000001");
pub const CLASS_SCI_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000002");
pub const CLASS_ADVISORY_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000003");
pub const CLASS_ARCHIVED_10A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000004");
pub const CLASS_DELETED_8_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000099");

// ─── TOS IDs ─────────────────────────────────────────────────────────────────
pub const TOS_MATH_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-5555-000000000001");
pub const TOS_SCI_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-5555-000000000002");

// ─── Competency IDs ──────────────────────────────────────────────────────────
pub const COMP_MATH_1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000001");
pub const COMP_MATH_2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000002");
pub const COMP_MATH_3_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000003");
pub const COMP_SCI_1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000004");
pub const COMP_SCI_2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000005");
pub const COMP_SCI_3_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000006");

// ─── Assessment IDs ──────────────────────────────────────────────────────────
pub const ASSESS_MATH_QUIZ1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000001");
pub const ASSESS_MATH_QUIZ2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000002");
pub const ASSESS_SCI_TEST1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000003");
pub const ASSESS_SCI_TEST2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000004");
pub const ASSESS_DELETED_MATH_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000099");

// ─── Question IDs ────────────────────────────────────────────────────────────
pub const Q_MATH_Q1_1: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000001");
pub const Q_MATH_Q1_2: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000002");
pub const Q_MATH_Q1_3: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000003");
pub const Q_MATH_Q1_4: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000004");
pub const Q_MATH_Q1_5: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000005");

pub const Q_MATH_Q2_1: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000001");
pub const Q_MATH_Q2_2: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000002");
pub const Q_MATH_Q2_3: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000003");
pub const Q_MATH_Q2_4: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000004");
pub const Q_MATH_Q2_5: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000005");

pub const Q_SCI_T1_1: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000001");
pub const Q_SCI_T1_2: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000002");
pub const Q_SCI_T1_3: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000003");
pub const Q_SCI_T1_4: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000004");
pub const Q_SCI_T1_5: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000005");

pub const Q_SCI_T2_1: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000001");
pub const Q_SCI_T2_2: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000002");
pub const Q_SCI_T2_3: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000003");
pub const Q_SCI_T2_4: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000004");
pub const Q_SCI_T2_5: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000005");

pub const Q_DELETED_1: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000001");
pub const Q_DELETED_2: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000002");
pub const Q_DELETED_3: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000003");
pub const Q_DELETED_4: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000004");
pub const Q_DELETED_5: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000005");

// ─── Assignment IDs ────────────────────────────────────────────────────────────
pub const ASSIGN_MATH_HW1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000001");
pub const ASSIGN_SCI_LAB_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000002");
pub const ASSIGN_MATH_PROJECT_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000003");
pub const ASSIGN_DELETED_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000099");

// ─── Submission IDs ──────────────────────────────────────────────────────────
pub const SUB_ASSESS_S01_MQ1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000001");
pub const SUB_ASSESS_S02_MQ1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000002");
pub const SUB_ASSESS_S03_MQ1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000003");
pub const SUB_ASSESS_S01_ST1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000004");
pub const SUB_ASSESS_S02_ST1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000005");

pub const SUB_ASSIGN_S01_HW1: Uuid = uuid!("a1b2c3d4-1111-2222-bbbb-000000000001");
pub const SUB_ASSIGN_S02_HW1: Uuid = uuid!("a1b2c3d4-1111-2222-bbbb-000000000002");
pub const SUB_ASSIGN_S01_LAB: Uuid = uuid!("a1b2c3d4-1111-2222-bbbb-000000000003");

// ─── Material IDs ────────────────────────────────────────────────────────────
pub const MAT_MATH_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000001");
pub const MAT_SCI_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000002");
pub const MAT_ADVISORY_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000003");
pub const MAT_ARCHIVED_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000004");

// ─── Fixtures ────────────────────────────────────────────────────────────────

pub fn e2e_school_settings(ctx: &SeedContext) -> SchoolSettingsSpec {
    SchoolSettingsSpec {
        id: 1,
        school_code: "E2E-TEST".into(),
        school_name: Some("Likha E2E Test School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        updated_at: ctx.now(),
    }
}

pub fn e2e_users(ctx: &SeedContext) -> Vec<UserSpec> {
    let created = ctx.days_ago(30);
    let activated = ctx.days_ago(29);
    let deleted = ctx.days_ago(6);

    vec![
        // Admin
        UserSpec {
            id: ADMIN_ID,
            username: "admin".into(),
            full_name: "System Administrator".into(),
            role: "admin".into(),
            password_hash: None,
            account_status: "pending_activation".into(),
            created_at: created,
            activated_at: None,
            deleted_at: None,
        },
        // Teachers
        UserSpec {
            id: TEACHER_01_ID,
            username: "teacher_01".into(),
            full_name: "Teacher One".into(),
            role: "teacher".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_TEACHER, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        },
        UserSpec {
            id: TEACHER_02_ID,
            username: "teacher_02".into(),
            full_name: "Teacher Two".into(),
            role: "teacher".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_TEACHER, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        },
        // Students
        UserSpec {
            id: STUDENT_01_ID,
            username: "student_01".into(),
            full_name: "Student One".into(),
            role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        },
        UserSpec {
            id: STUDENT_02_ID,
            username: "student_02".into(),
            full_name: "Student Two".into(),
            role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        },
        UserSpec {
            id: STUDENT_03_ID,
            username: "student_03".into(),
            full_name: "Student Three".into(),
            role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        },
        // Deleted student
        UserSpec {
            id: STUDENT_DELETED_ID,
            username: "student_deleted_99".into(),
            full_name: "Student Deleted 99".into(),
            role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: Some(deleted),
        },
    ]
}

pub fn e2e_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    let created = ctx.days_ago(25);
    let deleted = ctx.days_ago(5);

    vec![
        ClassSpec {
            id: CLASS_MATH_8A_ID,
            title: "Mathematics 8A".into(),
            description: Some("E2E test class".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: CLASS_SCI_8A_ID,
            title: "Science 8A".into(),
            description: Some("E2E test class".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: CLASS_ADVISORY_8A_ID,
            title: "Advisory 8A".into(),
            description: Some("E2E test class".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: true,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: CLASS_ARCHIVED_10A_ID,
            title: "Archived Class 10A".into(),
            description: Some("E2E test class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: true,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: CLASS_DELETED_8_ID,
            title: "Deleted Science 8 (should not appear)".into(),
            description: Some("E2E test class".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: Some(deleted),
        },
    ]
}

pub fn e2e_enrollments() -> Vec<EnrollmentSpec> {
    vec![
        // Teacher enrollments
        EnrollmentSpec { class_id: CLASS_MATH_8A_ID, user_id: TEACHER_01_ID },
        EnrollmentSpec { class_id: CLASS_SCI_8A_ID, user_id: TEACHER_01_ID },
        EnrollmentSpec { class_id: CLASS_ADVISORY_8A_ID, user_id: TEACHER_01_ID },
        EnrollmentSpec { class_id: CLASS_ADVISORY_8A_ID, user_id: TEACHER_02_ID },
        EnrollmentSpec { class_id: CLASS_ARCHIVED_10A_ID, user_id: TEACHER_02_ID },
        // Student enrollments
        EnrollmentSpec { class_id: CLASS_MATH_8A_ID, user_id: STUDENT_01_ID },
        EnrollmentSpec { class_id: CLASS_SCI_8A_ID, user_id: STUDENT_01_ID },
        EnrollmentSpec { class_id: CLASS_ADVISORY_8A_ID, user_id: STUDENT_01_ID },
        EnrollmentSpec { class_id: CLASS_MATH_8A_ID, user_id: STUDENT_02_ID },
        EnrollmentSpec { class_id: CLASS_SCI_8A_ID, user_id: STUDENT_02_ID },
        EnrollmentSpec { class_id: CLASS_ADVISORY_8A_ID, user_id: STUDENT_02_ID },
        EnrollmentSpec { class_id: CLASS_MATH_8A_ID, user_id: STUDENT_03_ID },
        EnrollmentSpec { class_id: CLASS_ADVISORY_8A_ID, user_id: STUDENT_03_ID },
    ]
}

pub fn e2e_tos() -> Vec<TosSpec> {
    vec![
        TosSpec {
            id: TOS_MATH_8A_ID,
            class_id: CLASS_MATH_8A_ID,
            period: 1,
            title: "TOS for Mathematics 8A - Q1".into(),
            template_type: "difficulty".into(),
            total_items: 30,
            time_limit_unit: "days".into(),
            ww_percent: 30.0,
            pt_percent: 50.0,
            qa_percent: 20.0,
            easy_percent: 15.0,
            average_percent: 20.0,
            difficult_percent: 15.0,
            remembering_percent: 15.0,
            understanding_percent: 15.0,
            applying_percent: 15.0,
            analyzing_percent: 0.0,
            evaluating_percent: 0.0,
            creating_percent: 0.0,
        },
        TosSpec {
            id: TOS_SCI_8A_ID,
            class_id: CLASS_SCI_8A_ID,
            period: 1,
            title: "TOS for Science 8A - Q1".into(),
            template_type: "bloom".into(),
            total_items: 30,
            time_limit_unit: "days".into(),
            ww_percent: 30.0,
            pt_percent: 50.0,
            qa_percent: 20.0,
            easy_percent: 15.0,
            average_percent: 20.0,
            difficult_percent: 15.0,
            remembering_percent: 15.0,
            understanding_percent: 15.0,
            applying_percent: 15.0,
            analyzing_percent: 0.0,
            evaluating_percent: 0.0,
            creating_percent: 0.0,
        },
    ]
}

pub fn e2e_competencies() -> Vec<CompetencySpec> {
    vec![
        CompetencySpec {
            id: COMP_MATH_1_ID,
            tos_id: TOS_MATH_8A_ID,
            code: Some("M8NS-Ia-1".into()),
            text: "Represents integers on number line".into(),
            time_units_taught: 5,
            order: 0,
        },
        CompetencySpec {
            id: COMP_MATH_2_ID,
            tos_id: TOS_MATH_8A_ID,
            code: Some("M8NS-Ib-2".into()),
            text: "Performs operations on integers".into(),
            time_units_taught: 5,
            order: 1,
        },
        CompetencySpec {
            id: COMP_MATH_3_ID,
            tos_id: TOS_MATH_8A_ID,
            code: Some("M8AL-Ia-1".into()),
            text: "Translates verbal phrases to mathematical expressions".into(),
            time_units_taught: 5,
            order: 2,
        },
        CompetencySpec {
            id: COMP_SCI_1_ID,
            tos_id: TOS_SCI_8A_ID,
            code: Some("S8MT-Ia-1".into()),
            text: "Describes the distribution of active volcanoes".into(),
            time_units_taught: 5,
            order: 0,
        },
        CompetencySpec {
            id: COMP_SCI_2_ID,
            tos_id: TOS_SCI_8A_ID,
            code: Some("S8MT-Ib-2".into()),
            text: "Explains how energy from volcanoes may be tapped".into(),
            time_units_taught: 5,
            order: 1,
        },
        CompetencySpec {
            id: COMP_SCI_3_ID,
            tos_id: TOS_SCI_8A_ID,
            code: Some("S8ES-Ia-1".into()),
            text: "Describes the different layers of the Earth".into(),
            time_units_taught: 5,
            order: 2,
        },
    ]
}

pub fn e2e_assessments(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(15);
    let now = ctx.now();

    vec![
        AssessmentSpec {
            id: ASSESS_MATH_QUIZ1_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Quiz 1 (Closed)".into(),
            description: None,
            time_limit_minutes: 30,
            open_at: now + chrono::Duration::days(-7),
            close_at: now + chrono::Duration::days(-1),
            show_results_immediately: true,
            total_points: 6,
            component: "written_work".into(),
            tos_id: TOS_MATH_8A_ID,
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: true,
            questions: vec![
                // Q1: multiple choice, easy, remembering
                QuestionSpec {
                    id: Q_MATH_Q1_1,
                    question_type: "multiple_choice".into(),
                    text: "What is the first concept in this topic?".into(),
                    points: 1,
                    order: 0,
                    is_multi_select: false,
                    tos_competency_id: Some(COMP_MATH_1_ID),
                    difficulty: Some("easy".into()),
                    cognitive_level: Some("remembering".into()),
                    choices: vec![
                        ChoiceSpec { text: "Option A".into(), is_correct: false, order: 0 },
                        ChoiceSpec { text: "Option B (correct)".into(), is_correct: true, order: 1 },
                        ChoiceSpec { text: "Option C".into(), is_correct: false, order: 2 },
                        ChoiceSpec { text: "Option D".into(), is_correct: false, order: 3 },
                    ],
                    answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into(), "Option B".into()] },
                },
                // Q2: multiple choice, medium, understanding
                QuestionSpec {
                    id: Q_MATH_Q1_2,
                    question_type: "multiple_choice".into(),
                    text: "Which statement best describes the second concept?".into(),
                    points: 2,
                    order: 1,
                    is_multi_select: false,
                    tos_competency_id: Some(COMP_MATH_2_ID),
                    difficulty: Some("medium".into()),
                    cognitive_level: Some("understanding".into()),
                    choices: vec![
                        ChoiceSpec { text: "Option A".into(), is_correct: false, order: 0 },
                        ChoiceSpec { text: "Option B".into(), is_correct: false, order: 1 },
                        ChoiceSpec { text: "Option C (correct)".into(), is_correct: true, order: 2 },
                        ChoiceSpec { text: "Option D".into(), is_correct: false, order: 3 },
                    ],
                    answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into(), "Option C".into()] },
                },
                // Q3: identification, easy, applying
                QuestionSpec {
                    id: Q_MATH_Q1_3,
                    question_type: "identification".into(),
                    text: "Name the key term for the third concept.".into(),
                    points: 1,
                    order: 2,
                    is_multi_select: false,
                    tos_competency_id: Some(COMP_MATH_1_ID),
                    difficulty: Some("easy".into()),
                    cognitive_level: Some("applying".into()),
                    choices: vec![],
                    answer_key: AnswerKeySpec { acceptable_answers: vec!["42".into(), "42-variant".into()] },
                },
                // Q4: identification, medium, analyzing
                QuestionSpec {
                    id: Q_MATH_Q1_4,
                    question_type: "identification".into(),
                    text: "Identify the principle used in the fourth concept.".into(),
                    points: 2,
                    order: 3,
                    is_multi_select: false,
                    tos_competency_id: Some(COMP_MATH_2_ID),
                    difficulty: Some("medium".into()),
                    cognitive_level: Some("analyzing".into()),
                    choices: vec![],
                    answer_key: AnswerKeySpec { acceptable_answers: vec!["principle".into(), "principle-variant".into()] },
                },
                // Q5: essay, hard, evaluating
                QuestionSpec {
                    id: Q_MATH_Q1_5,
                    question_type: "essay".into(),
                    text: "Explain the fifth concept in your own words.".into(),
                    points: 5,
                    order: 4,
                    is_multi_select: false,
                    tos_competency_id: Some(COMP_MATH_3_ID),
                    difficulty: Some("hard".into()),
                    cognitive_level: Some("evaluating".into()),
                    choices: vec![],
                    answer_key: AnswerKeySpec { acceptable_answers: vec![] },
                },
            ],
        },
        AssessmentSpec {
            id: ASSESS_MATH_QUIZ2_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Quiz 2 (Open)".into(),
            description: None,
            time_limit_minutes: 30,
            open_at: now + chrono::Duration::days(-1),
            close_at: now + chrono::Duration::days(7),
            show_results_immediately: false,
            total_points: 6,
            component: "performance_task".into(),
            tos_id: TOS_MATH_8A_ID,
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: false,
            questions: vec![
                QuestionSpec { id: Q_MATH_Q2_1, question_type: "multiple_choice".into(), text: "Open quiz Q1".into(), points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(COMP_MATH_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![ ChoiceSpec { text: "A".into(), is_correct: false, order: 0 }, ChoiceSpec { text: "B (correct)".into(), is_correct: true, order: 1 }, ], answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into()] } },
                QuestionSpec { id: Q_MATH_Q2_2, question_type: "multiple_choice".into(), text: "Open quiz Q2".into(), points: 2, order: 1, is_multi_select: false, tos_competency_id: Some(COMP_MATH_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()), choices: vec![ ChoiceSpec { text: "A".into(), is_correct: false, order: 0 }, ChoiceSpec { text: "B".into(), is_correct: false, order: 1 }, ChoiceSpec { text: "C (correct)".into(), is_correct: true, order: 2 }, ], answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] } },
                QuestionSpec { id: Q_MATH_Q2_3, question_type: "identification".into(), text: "Open quiz Q3".into(), points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(COMP_MATH_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("applying".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_MATH_Q2_4, question_type: "identification".into(), text: "Open quiz Q4".into(), points: 2, order: 3, is_multi_select: false, tos_competency_id: Some(COMP_MATH_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("analyzing".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_MATH_Q2_5, question_type: "essay".into(), text: "Open quiz Q5 (essay)".into(), points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(COMP_MATH_3_ID), difficulty: Some("hard".into()), cognitive_level: Some("evaluating".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec![] } },
            ],
        },
        AssessmentSpec {
            id: ASSESS_SCI_TEST1_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Test 1 (Closed)".into(),
            description: None,
            time_limit_minutes: 30,
            open_at: now + chrono::Duration::days(-10),
            close_at: now + chrono::Duration::days(-2),
            show_results_immediately: true,
            total_points: 6,
            component: "quarterly_assessment".into(),
            tos_id: TOS_SCI_8A_ID,
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: true,
            questions: vec![
                QuestionSpec { id: Q_SCI_T1_1, question_type: "multiple_choice".into(), text: "Science Q1".into(), points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(COMP_SCI_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![ ChoiceSpec { text: "A".into(), is_correct: false, order: 0 }, ChoiceSpec { text: "B (correct)".into(), is_correct: true, order: 1 }, ], answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into()] } },
                QuestionSpec { id: Q_SCI_T1_2, question_type: "multiple_choice".into(), text: "Science Q2".into(), points: 2, order: 1, is_multi_select: false, tos_competency_id: Some(COMP_SCI_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()), choices: vec![ ChoiceSpec { text: "A".into(), is_correct: false, order: 0 }, ChoiceSpec { text: "B".into(), is_correct: false, order: 1 }, ChoiceSpec { text: "C (correct)".into(), is_correct: true, order: 2 }, ], answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] } },
                QuestionSpec { id: Q_SCI_T1_3, question_type: "identification".into(), text: "Science Q3".into(), points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(COMP_SCI_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("applying".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_SCI_T1_4, question_type: "identification".into(), text: "Science Q4".into(), points: 2, order: 3, is_multi_select: false, tos_competency_id: Some(COMP_SCI_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("analyzing".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_SCI_T1_5, question_type: "essay".into(), text: "Science Q5 (essay)".into(), points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(COMP_SCI_3_ID), difficulty: Some("hard".into()), cognitive_level: Some("evaluating".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec![] } },
            ],
        },
        AssessmentSpec {
            id: ASSESS_SCI_TEST2_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Test 2 (Open)".into(),
            description: None,
            time_limit_minutes: 30,
            open_at: now + chrono::Duration::days(1),
            close_at: now + chrono::Duration::days(14),
            show_results_immediately: false,
            total_points: 6,
            component: "written_work".into(),
            tos_id: TOS_SCI_8A_ID,
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: false,
            questions: vec![
                QuestionSpec { id: Q_SCI_T2_1, question_type: "multiple_choice".into(), text: "Future Q1".into(), points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(COMP_SCI_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![ ChoiceSpec { text: "A".into(), is_correct: false, order: 0 }, ChoiceSpec { text: "B (correct)".into(), is_correct: true, order: 1 }, ], answer_key: AnswerKeySpec { acceptable_answers: vec!["B".into()] } },
                QuestionSpec { id: Q_SCI_T2_2, question_type: "multiple_choice".into(), text: "Future Q2".into(), points: 2, order: 1, is_multi_select: false, tos_competency_id: Some(COMP_SCI_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()), choices: vec![ ChoiceSpec { text: "A".into(), is_correct: false, order: 0 }, ChoiceSpec { text: "B".into(), is_correct: false, order: 1 }, ChoiceSpec { text: "C (correct)".into(), is_correct: true, order: 2 }, ], answer_key: AnswerKeySpec { acceptable_answers: vec!["C".into()] } },
                QuestionSpec { id: Q_SCI_T2_3, question_type: "identification".into(), text: "Future Q3".into(), points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(COMP_SCI_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("applying".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_SCI_T2_4, question_type: "identification".into(), text: "Future Q4".into(), points: 2, order: 3, is_multi_select: false, tos_competency_id: Some(COMP_SCI_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("analyzing".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_SCI_T2_5, question_type: "essay".into(), text: "Future Q5 (essay)".into(), points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(COMP_SCI_3_ID), difficulty: Some("hard".into()), cognitive_level: Some("evaluating".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec![] } },
            ],
        },
        AssessmentSpec {
            id: ASSESS_DELETED_MATH_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "[DELETED] Review Test - Math 8A".into(),
            description: None,
            time_limit_minutes: 30,
            open_at: now + chrono::Duration::days(-8),
            close_at: now + chrono::Duration::days(-4),
            show_results_immediately: false,
            total_points: 6,
            component: "written_work".into(),
            tos_id: TOS_MATH_8A_ID,
            created_at: created,
            deleted_at: Some(ctx.days_ago(4)),
            is_published: false,
            results_released: false,
            questions: vec![
                QuestionSpec { id: Q_DELETED_1, question_type: "multiple_choice".into(), text: "Deleted Q1".into(), points: 1, order: 0, is_multi_select: false, tos_competency_id: Some(COMP_MATH_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("remembering".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec![] } },
                QuestionSpec { id: Q_DELETED_2, question_type: "multiple_choice".into(), text: "Deleted Q2".into(), points: 2, order: 1, is_multi_select: false, tos_competency_id: Some(COMP_MATH_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("understanding".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec![] } },
                QuestionSpec { id: Q_DELETED_3, question_type: "identification".into(), text: "Deleted Q3".into(), points: 1, order: 2, is_multi_select: false, tos_competency_id: Some(COMP_MATH_1_ID), difficulty: Some("easy".into()), cognitive_level: Some("applying".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_DELETED_4, question_type: "identification".into(), text: "Deleted Q4".into(), points: 2, order: 3, is_multi_select: false, tos_competency_id: Some(COMP_MATH_2_ID), difficulty: Some("medium".into()), cognitive_level: Some("analyzing".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec!["ans".into()] } },
                QuestionSpec { id: Q_DELETED_5, question_type: "essay".into(), text: "Deleted Q5".into(), points: 5, order: 4, is_multi_select: false, tos_competency_id: Some(COMP_MATH_3_ID), difficulty: Some("hard".into()), cognitive_level: Some("evaluating".into()), choices: vec![], answer_key: AnswerKeySpec { acceptable_answers: vec![] } },
            ],
        },
    ]
}

pub fn e2e_assignment_submissions(ctx: &SeedContext) -> Vec<AssignmentSubmissionSpec> {
    let submitted = ctx.days_ago(4);
    let graded = ctx.days_ago(3);

    vec![
        // Student 01 - Math Homework 1 (submitted and graded)
        AssignmentSubmissionSpec {
            id: SUB_ASSIGN_S01_HW1,
            assignment_id: ASSIGN_MATH_HW1_ID,
            student_id: STUDENT_01_ID,
            text: Some("Completed homework".into()),
            status: "graded".into(),
            points: Some(45), // 90% of 50
            feedback: Some("Good work!".into()),
            graded_by: Some(TEACHER_01_ID),
            submitted_at: submitted,
            graded_at: Some(graded),
        },
        // Student 02 - Math Homework 1 (submitted, not graded)
        AssignmentSubmissionSpec {
            id: SUB_ASSIGN_S02_HW1,
            assignment_id: ASSIGN_MATH_HW1_ID,
            student_id: STUDENT_02_ID,
            text: Some("My submission".into()),
            status: "submitted".into(),
            points: None,
            feedback: None,
            graded_by: None,
            submitted_at: submitted,
            graded_at: None,
        },
        // Student 01 - Science Lab (submitted and graded)
        AssignmentSubmissionSpec {
            id: SUB_ASSIGN_S01_LAB,
            assignment_id: ASSIGN_SCI_LAB_ID,
            student_id: STUDENT_01_ID,
            text: Some("Lab report completed".into()),
            status: "graded".into(),
            points: Some(85), // 85/100
            feedback: Some("Well done".into()),
            graded_by: Some(TEACHER_01_ID),
            submitted_at: submitted,
            graded_at: Some(graded),
        },
    ]
}

pub fn e2e_grade_records() -> Vec<GradeRecordSpec> {
    vec![
        // Math 8A - uses math_sci preset
        GradeRecordSpec {
            class_id: CLASS_MATH_8A_ID,
            grading_period_type: "math_sci".into(),
            ww_weight: 30.0,
            pt_weight: 50.0,
            qa_weight: 20.0,
        },
        // Science 8A - uses math_sci preset
        GradeRecordSpec {
            class_id: CLASS_SCI_8A_ID,
            grading_period_type: "math_sci".into(),
            ww_weight: 30.0,
            pt_weight: 50.0,
            qa_weight: 20.0,
        },
    ]
}

pub fn e2e_assignments(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(15);
    let now = ctx.now();

    vec![
        AssignmentSpec {
            id: ASSIGN_MATH_HW1_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Homework 1 (Past Due)".into(),
            instructions: "Complete the assignment as instructed.".into(),
            total_points: 50,
            allows_text_submission: true,
            allows_file_submission: false,
            due_at: now + chrono::Duration::days(-5),
            component: "written_work".into(),
            created_at: created,
            deleted_at: None,
            is_published: true,
            grading_period_number: 1,
        },
        AssignmentSpec {
            id: ASSIGN_SCI_LAB_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Lab Report (Due Soon)".into(),
            instructions: "Complete the assignment as instructed.".into(),
            total_points: 100,
            allows_text_submission: true,
            allows_file_submission: false,
            due_at: now + chrono::Duration::days(2),
            component: "performance_task".into(),
            created_at: created,
            deleted_at: None,
            is_published: true,
            grading_period_number: 1,
        },
        AssignmentSpec {
            id: ASSIGN_MATH_PROJECT_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Project (Future)".into(),
            instructions: "Complete the assignment as instructed.".into(),
            total_points: 200,
            allows_text_submission: true,
            allows_file_submission: false,
            due_at: now + chrono::Duration::days(14),
            component: "performance_task".into(),
            created_at: created,
            deleted_at: None,
            is_published: true,
            grading_period_number: 1,
        },
        AssignmentSpec {
            id: ASSIGN_DELETED_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "[DELETED] Extra Credit".into(),
            instructions: "Complete the assignment as instructed.".into(),
            total_points: 50,
            allows_text_submission: true,
            allows_file_submission: false,
            due_at: now + chrono::Duration::days(-3),
            component: "written_work".into(),
            created_at: created,
            deleted_at: Some(ctx.days_ago(3)),
            is_published: false,
            grading_period_number: 1,
        },
    ]
}

pub fn e2e_materials(ctx: &SeedContext) -> Vec<MaterialSpec> {
    vec![
        MaterialSpec {
            id: MAT_MATH_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Unit 1: Integer Operations".into(),
            description: Some("E2E test material".into()),
            content_text: Some("## Integer Operations...".into()),
            order_index: 0,
            created_at: ctx.now(),
        },
        MaterialSpec {
            id: MAT_SCI_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Unit 1: Volcanoes".into(),
            description: Some("E2E test material".into()),
            content_text: Some("## Volcanoes...".into()),
            order_index: 0,
            created_at: ctx.now(),
        },
        MaterialSpec {
            id: MAT_ADVISORY_ID,
            class_id: CLASS_ADVISORY_8A_ID,
            title: "Advisory Guidelines".into(),
            description: Some("E2E test material".into()),
            content_text: Some("## Advisory Guidelines...".into()),
            order_index: 0,
            created_at: ctx.now(),
        },
        MaterialSpec {
            id: MAT_ARCHIVED_ID,
            class_id: CLASS_ARCHIVED_10A_ID,
            title: "Old Reference Material".into(),
            description: Some("E2E test material".into()),
            content_text: Some("## Old Reference...".into()),
            order_index: 0,
            created_at: ctx.now(),
        },
    ]
}

pub fn e2e_assessment_submissions(ctx: &SeedContext) -> Vec<AssessmentSubmissionSpec> {
    let started_mq1 = ctx.days_ago(6);
    let submitted_mq1 = started_mq1 + chrono::Duration::minutes(30);
    let started_st1 = ctx.days_ago(9);
    let submitted_st1 = started_st1 + chrono::Duration::minutes(30);

    vec![
        // Student 01 - Math Quiz 1 (all correct except essay)
        AssessmentSubmissionSpec {
            id: SUB_ASSESS_S01_MQ1,
            assessment_id: ASSESS_MATH_QUIZ1_ID,
            student_id: STUDENT_01_ID,
            started_at: started_mq1,
            submitted_at: Some(submitted_mq1),
            total_points: 6.0, // 1 + 2 + 1 + 2 + 0 = 6
            answers: vec![
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_1, choice_ids: vec![], text: None, is_correct: Some(true), points: 1.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_2, choice_ids: vec![], text: None, is_correct: Some(true), points: 2.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_3, choice_ids: vec![], text: Some("42".into()), is_correct: Some(true), points: 1.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_4, choice_ids: vec![], text: Some("principle".into()), is_correct: Some(true), points: 2.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_5, choice_ids: vec![], text: None, is_correct: None, points: 0.0 },
            ],
        },
        // Student 02 - Math Quiz 1 (only Q1 correct)
        AssessmentSubmissionSpec {
            id: SUB_ASSESS_S02_MQ1,
            assessment_id: ASSESS_MATH_QUIZ1_ID,
            student_id: STUDENT_02_ID,
            started_at: started_mq1,
            submitted_at: Some(submitted_mq1),
            total_points: 1.0,
            answers: vec![
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_1, choice_ids: vec![], text: None, is_correct: Some(true), points: 1.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_2, choice_ids: vec![], text: None, is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_3, choice_ids: vec![], text: Some("wrong".into()), is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_4, choice_ids: vec![], text: Some("wrong".into()), is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_5, choice_ids: vec![], text: None, is_correct: None, points: 0.0 },
            ],
        },
        // Student 03 - Math Quiz 1 (all wrong)
        AssessmentSubmissionSpec {
            id: SUB_ASSESS_S03_MQ1,
            assessment_id: ASSESS_MATH_QUIZ1_ID,
            student_id: STUDENT_03_ID,
            started_at: started_mq1 + chrono::Duration::days(1),
            submitted_at: Some(submitted_mq1 + chrono::Duration::days(1)),
            total_points: 0.0,
            answers: vec![
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_1, choice_ids: vec![], text: None, is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_2, choice_ids: vec![], text: None, is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_3, choice_ids: vec![], text: Some("wrong".into()), is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_4, choice_ids: vec![], text: Some("wrong".into()), is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_MATH_Q1_5, choice_ids: vec![], text: None, is_correct: None, points: 0.0 },
            ],
        },
        // Student 01 - Science Test 1 (all correct except essay)
        AssessmentSubmissionSpec {
            id: SUB_ASSESS_S01_ST1,
            assessment_id: ASSESS_SCI_TEST1_ID,
            student_id: STUDENT_01_ID,
            started_at: started_st1,
            submitted_at: Some(submitted_st1),
            total_points: 6.0,
            answers: vec![
                SubmissionAnswerSpec { question_id: Q_SCI_T1_1, choice_ids: vec![], text: None, is_correct: Some(true), points: 1.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_2, choice_ids: vec![], text: None, is_correct: Some(true), points: 2.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_3, choice_ids: vec![], text: Some("ans".into()), is_correct: Some(true), points: 1.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_4, choice_ids: vec![], text: Some("ans".into()), is_correct: Some(true), points: 2.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_5, choice_ids: vec![], text: None, is_correct: None, points: 0.0 },
            ],
        },
        // Student 02 - Science Test 1 (only Q1 correct)
        AssessmentSubmissionSpec {
            id: SUB_ASSESS_S02_ST1,
            assessment_id: ASSESS_SCI_TEST1_ID,
            student_id: STUDENT_02_ID,
            started_at: started_st1,
            submitted_at: Some(submitted_st1),
            total_points: 1.0,
            answers: vec![
                SubmissionAnswerSpec { question_id: Q_SCI_T1_1, choice_ids: vec![], text: None, is_correct: Some(true), points: 1.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_2, choice_ids: vec![], text: None, is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_3, choice_ids: vec![], text: Some("wrong".into()), is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_4, choice_ids: vec![], text: Some("wrong".into()), is_correct: Some(false), points: 0.0 },
                SubmissionAnswerSpec { question_id: Q_SCI_T1_5, choice_ids: vec![], text: None, is_correct: None, points: 0.0 },
            ],
        },
    ]
}
