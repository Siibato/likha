//! Common fixtures shared across all quarters: users, classes, enrollments, TOS, competencies, materials.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::{cid, uid, tid, compid, mid};
use super::super::shared::{PASSWORD_TEACHER, PASSWORD_STUDENT};

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
        school_code: "LIKHA1".into(),
        school_name: Some("Likha National High School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        school_district: None,
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
        // Q1
        TosSpec {
            id: tid("english_9a_tos_q1"), class_id: cid("english_9a"), period: 1,
            title: "TOS for English 9 - Q1".into(), template_type: "difficulty".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("science_9a_tos_q1"), class_id: cid("science_9a"), period: 1,
            title: "TOS for Science 9 - Q1".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("advisory_9a_tos_q1"), class_id: cid("advisory_9a"), period: 1,
            title: "TOS for Advisory 9-A - Q1".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
        // Q2
        TosSpec {
            id: tid("english_9a_tos_q2"), class_id: cid("english_9a"), period: 2,
            title: "TOS for English 9 - Q2".into(), template_type: "difficulty".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("science_9a_tos_q2"), class_id: cid("science_9a"), period: 2,
            title: "TOS for Science 9 - Q2".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("advisory_9a_tos_q2"), class_id: cid("advisory_9a"), period: 2,
            title: "TOS for Advisory 9-A - Q2".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
        // Q3
        TosSpec {
            id: tid("english_9a_tos_q3"), class_id: cid("english_9a"), period: 3,
            title: "TOS for English 9 - Q3".into(), template_type: "difficulty".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("science_9a_tos_q3"), class_id: cid("science_9a"), period: 3,
            title: "TOS for Science 9 - Q3".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("advisory_9a_tos_q3"), class_id: cid("advisory_9a"), period: 3,
            title: "TOS for Advisory 9-A - Q3".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
        // Q4
        TosSpec {
            id: tid("english_9a_tos_q4"), class_id: cid("english_9a"), period: 4,
            title: "TOS for English 9 - Q4".into(), template_type: "difficulty".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("science_9a_tos_q4"), class_id: cid("science_9a"), period: 4,
            title: "TOS for Science 9 - Q4".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("advisory_9a_tos_q4"), class_id: cid("advisory_9a"), period: 4,
            title: "TOS for Advisory 9-A - Q4".into(), template_type: "difficulty".into(),
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
        // English 9 Q1
        CompetencySpec { id: compid("e9q1_comp_0"), tos_id: tid("english_9a_tos_q1"), code: Some("E9PL-Ia-1".into()), text: "Listen to get information from oral texts".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("e9q1_comp_1"), tos_id: tid("english_9a_tos_q1"), code: Some("E9RC-Ib-2".into()), text: "Identify text types (narrative, expository, persuasive)".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("e9q1_comp_2"), tos_id: tid("english_9a_tos_q1"), code: Some("E9LT-Ic-3".into()), text: "Explain literary devices used in Afro-Asian literature".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("e9q1_comp_3"), tos_id: tid("english_9a_tos_q1"), code: Some("E9WC-Id-4".into()), text: "Write a persuasive essay with clear arguments".into(), time_units_taught: 5, order: 3 },
        // Science 9 Q1
        CompetencySpec { id: compid("s9q1_comp_0"), tos_id: tid("science_9a_tos_q1"), code: Some("S9ES-Ia-1".into()), text: "Describe the internal structure of the Earth".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s9q1_comp_1"), tos_id: tid("science_9a_tos_q1"), code: Some("S9ES-Ib-2".into()), text: "Explain the theory of plate tectonics".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s9q1_comp_2"), tos_id: tid("science_9a_tos_q1"), code: Some("S9LT-Ic-3".into()), text: "Describe how genetic information is passed from parents to offspring".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s9q1_comp_3"), tos_id: tid("science_9a_tos_q1"), code: Some("S9MT-Id-4".into()), text: "Explain how different factors affect the rate of chemical reactions".into(), time_units_taught: 5, order: 3 },
        // Advisory 9-A Q1
        CompetencySpec { id: compid("a9q1_comp_0"), tos_id: tid("advisory_9a_tos_q1"), code: Some("AD9PH-Ia-1".into()), text: "Demonstrate positive personal health practices".into(), time_units_taught: 3, order: 0 },
        CompetencySpec { id: compid("a9q1_comp_1"), tos_id: tid("advisory_9a_tos_q1"), code: Some("AD9PH-Ib-1".into()), text: "Explain the dimensions of holistic health".into(), time_units_taught: 3, order: 1 },
        // English 9 Q2
        CompetencySpec { id: compid("e9q2_comp_0"), tos_id: tid("english_9a_tos_q2"), code: Some("E9OC-IIa-1".into()), text: "Deliver a speech of introduction effectively".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("e9q2_comp_1"), tos_id: tid("english_9a_tos_q2"), code: Some("E9OC-IIb-2".into()), text: "Use modal verbs appropriately in sentences".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("e9q2_comp_2"), tos_id: tid("english_9a_tos_q2"), code: Some("E9OC-IIc-3".into()), text: "Convert direct speech to reported speech".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("e9q2_comp_3"), tos_id: tid("english_9a_tos_q2"), code: Some("E9WC-IId-4".into()), text: "Write a persuasive speech using rhetorical devices".into(), time_units_taught: 5, order: 3 },
        // Science 9 Q2
        CompetencySpec { id: compid("s9q2_comp_0"), tos_id: tid("science_9a_tos_q2"), code: Some("S9ES-IIa-1".into()), text: "Describe the components of an ecosystem".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s9q2_comp_1"), tos_id: tid("science_9a_tos_q2"), code: Some("S9ES-IIb-2".into()), text: "Explain energy transfer through trophic levels".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s9q2_comp_2"), tos_id: tid("science_9a_tos_q2"), code: Some("S9LT-IIc-3".into()), text: "Explain natural selection and adaptation".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s9q2_comp_3"), tos_id: tid("science_9a_tos_q2"), code: Some("S9MT-IId-4".into()), text: "Propose strategies to protect Philippine biodiversity".into(), time_units_taught: 5, order: 3 },
        // Advisory 9-A Q2
        CompetencySpec { id: compid("a9q2_comp_0"), tos_id: tid("advisory_9a_tos_q2"), code: Some("AD9PH-IIa-1".into()), text: "Evaluate nutritional value of common foods".into(), time_units_taught: 3, order: 0 },
        CompetencySpec { id: compid("a9q2_comp_1"), tos_id: tid("advisory_9a_tos_q2"), code: Some("AD9PH-IIb-1".into()), text: "Identify the effects of substance abuse on health".into(), time_units_taught: 3, order: 1 },
        // English 9 Q3
        CompetencySpec { id: compid("e9q3_comp_0"), tos_id: tid("english_9a_tos_q3"), code: Some("E9RS-IIIa-1".into()), text: "Conduct research using credible sources".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("e9q3_comp_1"), tos_id: tid("english_9a_tos_q3"), code: Some("E9RS-IIIb-2".into()), text: "Evaluate source credibility and bias".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("e9q3_comp_2"), tos_id: tid("english_9a_tos_q3"), code: Some("E9ML-IIIc-3".into()), text: "Analyze persuasive techniques in media messages".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("e9q3_comp_3"), tos_id: tid("english_9a_tos_q3"), code: Some("E9ML-IIId-4".into()), text: "Create a multimedia presentation for a target audience".into(), time_units_taught: 5, order: 3 },
        // Science 9 Q3
        CompetencySpec { id: compid("s9q3_comp_0"), tos_id: tid("science_9a_tos_q3"), code: Some("S9FM-IIIa-1".into()), text: "Describe Newton's laws of motion".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s9q3_comp_1"), tos_id: tid("science_9a_tos_q3"), code: Some("S9FM-IIIb-2".into()), text: "Calculate speed, velocity, and acceleration".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s9q3_comp_2"), tos_id: tid("science_9a_tos_q3"), code: Some("S9WE-IIIc-3".into()), text: "Distinguish between kinetic and potential energy".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s9q3_comp_3"), tos_id: tid("science_9a_tos_q3"), code: Some("S9WE-IIId-4".into()), text: "Apply the law of conservation of energy".into(), time_units_taught: 5, order: 3 },
        // Advisory 9-A Q3
        CompetencySpec { id: compid("a9q3_comp_0"), tos_id: tid("advisory_9a_tos_q3"), code: Some("AD9SE-IIIa-1".into()), text: "Demonstrate assertiveness in peer situations".into(), time_units_taught: 3, order: 0 },
        CompetencySpec { id: compid("a9q3_comp_1"), tos_id: tid("advisory_9a_tos_q3"), code: Some("AD9SE-IIIb-1".into()), text: "Evaluate consequences of decisions on relationships".into(), time_units_taught: 3, order: 1 },
        // English 9 Q4
        CompetencySpec { id: compid("e9q4_comp_0"), tos_id: tid("english_9a_tos_q4"), code: Some("E9CW-IVa-1".into()), text: "Use figurative language in creative writing".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("e9q4_comp_1"), tos_id: tid("english_9a_tos_q4"), code: Some("E9CW-IVb-2".into()), text: "Write a short story with clear plot structure".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("e9q4_comp_2"), tos_id: tid("english_9a_tos_q4"), code: Some("E9LC-IVc-3".into()), text: "Analyze a literary text using biographical criticism".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("e9q4_comp_3"), tos_id: tid("english_9a_tos_q4"), code: Some("E9LC-IVd-4".into()), text: "Write a critical review of a contemporary novel".into(), time_units_taught: 5, order: 3 },
        // Science 9 Q4
        CompetencySpec { id: compid("s9q4_comp_0"), tos_id: tid("science_9a_tos_q4"), code: Some("S9EM-IVa-1".into()), text: "Describe the relationship between electricity and magnetism".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s9q4_comp_1"), tos_id: tid("science_9a_tos_q4"), code: Some("S9EM-IVb-2".into()), text: "Compare series and parallel circuits".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s9q4_comp_2"), tos_id: tid("science_9a_tos_q4"), code: Some("S9CC-IVc-3".into()), text: "Explain the greenhouse effect and its causes".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s9q4_comp_3"), tos_id: tid("science_9a_tos_q4"), code: Some("S9CC-IVd-4".into()), text: "Propose solutions to mitigate climate change".into(), time_units_taught: 5, order: 3 },
        // Advisory 9-A Q4
        CompetencySpec { id: compid("a9q4_comp_0"), tos_id: tid("advisory_9a_tos_q4"), code: Some("AD9CP-IVa-1".into()), text: "Develop a personal career plan based on skills and interests".into(), time_units_taught: 3, order: 0 },
        CompetencySpec { id: compid("a9q4_comp_1"), tos_id: tid("advisory_9a_tos_q4"), code: Some("AD9CP-IVb-1".into()), text: "Create a monthly budget and explain the importance of saving".into(), time_units_taught: 3, order: 1 },
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
