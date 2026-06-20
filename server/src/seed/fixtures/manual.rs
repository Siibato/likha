//! Manual seeding fixtures (stub for future implementation).
//!
//! This will contain the large-scale seed data:
//! - 75 users (5 teachers + 70 students, admin created separately by seed_admin)
//! - 15 classes
//! - 440 enrollments
//! - 15 TOS with 60 competencies
//! - 30-45 assessments
//! - 30-45 assignments
//! - etc.

use uuid::Uuid;

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use crate::seed::tools::seed_id;

use super::shared::*;

pub fn manual_users(ctx: &SeedContext) -> Vec<UserSpec> {
    let created = ctx.days_ago(30);
    let activated = ctx.days_ago(29);
    let deleted = ctx.days_ago(6);
    let mut users = Vec::with_capacity(76);

    // Teachers (5)
    for i in 1..=5 {
        let username = teacher_username(i);
        let full_name = teacher_full_name(i);
        users.push(UserSpec {
            id: user_id(&username),
            username: username.clone(),
            full_name,
            role: "teacher".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_TEACHER, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        });
    }

    // Students (70)
    for i in 1..=70 {
        let username = student_username(i);
        let full_name = student_full_name(i);
        users.push(UserSpec {
            id: user_id(&username),
            username: username.clone(),
            full_name,
            role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        });
    }

    // Soft-deleted student
    users.push(UserSpec {
        id: user_id("student_deleted_99"),
        username: "student_deleted_99".into(),
        full_name: "Student Deleted 99".into(),
        role: "student".into(),
        password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
        account_status: "active".into(),
        created_at: created,
        activated_at: Some(activated),
        deleted_at: Some(deleted),
    });

    users
}

pub fn manual_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    let created = ctx.days_ago(25);
    let deleted = ctx.days_ago(5);

    vec![
        // Classes 1-3: Grade 8, teacher_01, quarter
        ClassSpec {
            id: class_id("math_8a"),
            title: "Mathematics 8A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("science_8a"),
            title: "Science 8A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("english_8a"),
            title: "English 8A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // Classes 4-6: Grade 10, teacher_02, quarter
        ClassSpec {
            id: class_id("math_10a"),
            title: "Mathematics 10A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("science_10a"),
            title: "Science 10A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("english_10a"),
            title: "English 10A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // Classes 7-9: Grade 12, teacher_03, semester
        ClassSpec {
            id: class_id("math_12a"),
            title: "Mathematics 12A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("12".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("science_12a"),
            title: "Science 12A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("12".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("english_12a"),
            title: "English 12A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("12".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // Classes 10-12: Grade 8B, teacher_04, quarter
        ClassSpec {
            id: class_id("math_8b"),
            title: "Mathematics 8B".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("science_8b"),
            title: "Science 8B".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("english_8b"),
            title: "English 8B".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // Classes 13-14: Advisory classes, teacher_05
        ClassSpec {
            id: class_id("advisory_8a"),
            title: "Advisory 8A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: true,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: class_id("advisory_10a"),
            title: "Advisory 10A".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: true,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // Class 15: Archived class
        ClassSpec {
            id: class_id("math_10b_archived"),
            title: "Mathematics 10B (Archived)".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: true,
            created_at: created,
            deleted_at: None,
        },
        // Soft-deleted class (should not appear in UI)
        ClassSpec {
            id: class_id("deleted_science_8"),
            title: "Deleted Science 8 (should not appear)".into(),
            description: Some("Seeded class for manual testing".into()),
            grade_level: Some("8".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: Some(deleted),
        },
    ]
}

pub fn manual_enrollments() -> Vec<EnrollmentSpec> {
    let mut enrollments = Vec::with_capacity(440);

    // Class IDs in order (15 classes + 1 deleted)
    let class_ids = [
        class_id("math_8a"),      // 0 - teacher_01
        class_id("science_8a"),   // 1 - teacher_01
        class_id("english_8a"),   // 2 - teacher_01
        class_id("math_10a"),     // 3 - teacher_02
        class_id("science_10a"),  // 4 - teacher_02
        class_id("english_10a"),  // 5 - teacher_02
        class_id("math_12a"),     // 6 - teacher_03
        class_id("science_12a"),  // 7 - teacher_03
        class_id("english_12a"),  // 8 - teacher_03
        class_id("math_8b"),      // 9 - teacher_04
        class_id("science_8b"),  // 10 - teacher_04
        class_id("english_8b"),   // 11 - teacher_04
        class_id("advisory_8a"),  // 12 - teacher_05
        class_id("advisory_10a"), // 13 - teacher_05
        class_id("math_10b_archived"), // 14 - teacher_05
    ];

    // Teacher enrollments - each teacher in exactly 3 classes
    let teacher_ids = [
        user_id("teacher_01"),
        user_id("teacher_02"),
        user_id("teacher_03"),
        user_id("teacher_04"),
        user_id("teacher_05"),
    ];

    for (teacher_idx, teacher_id) in teacher_ids.iter().enumerate() {
        for class_offset in 0..3 {
            let class_idx = teacher_idx * 3 + class_offset;
            if class_idx < class_ids.len() {
                enrollments.push(EnrollmentSpec {
                    class_id: class_ids[class_idx],
                    user_id: *teacher_id,
                });
            }
        }
    }

    // Student enrollments - deterministic modulo rule
    // student_i enrolled in classes where: (class_idx + i * 3) % 15 < 7
    for student_idx in 1..=70 {
        let username = student_username(student_idx);
        let student_id = user_id(&username);

        for (class_idx, class_id) in class_ids.iter().enumerate() {
            if (class_idx as u32 + student_idx * 3) % 15 < 7 {
                enrollments.push(EnrollmentSpec {
                    class_id: *class_id,
                    user_id: student_id,
                });
            }
        }
    }

    // Advisory classes: add ALL grade-appropriate students
    // Advisory 8A: all students from grade 8 classes (math_8a, science_8a, english_8a, math_8b, science_8b, english_8b)
    let grade_8_classes = [0, 1, 2, 9, 10, 11]; // indices of grade 8 classes
    let advisory_8a_id = class_ids[12];

    // Advisory 10A: all students from grade 10 classes
    let grade_10_classes = [3, 4, 5]; // indices of grade 10 classes
    let advisory_10a_id = class_ids[13];

    // Students already enrolled in grade 8 classes via the modulo rule
    // Ensure they're also in advisory
    for student_idx in 1..=70 {
        let username = student_username(student_idx);
        let student_id = user_id(&username);

        // Check if student is in any grade 8 class - if so, add to advisory 8A
        let in_grade_8 = grade_8_classes.iter().any(|&class_idx| {
            (class_idx as u32 + student_idx * 3) % 15 < 7
        });

        if in_grade_8 {
            // Check if not already enrolled
            if !enrollments.iter().any(|e| e.class_id == advisory_8a_id && e.user_id == student_id) {
                enrollments.push(EnrollmentSpec {
                    class_id: advisory_8a_id,
                    user_id: student_id,
                });
            }
        }

        // Check if student is in any grade 10 class - if so, add to advisory 10A
        let in_grade_10 = grade_10_classes.iter().any(|&class_idx| {
            (class_idx as u32 + student_idx * 3) % 15 < 7
        });

        if in_grade_10 {
            if !enrollments.iter().any(|e| e.class_id == advisory_10a_id && e.user_id == student_id) {
                enrollments.push(EnrollmentSpec {
                    class_id: advisory_10a_id,
                    user_id: student_id,
                });
            }
        }
    }

    enrollments
}

pub fn manual_tos() -> Vec<TosSpec> {
    let class_names = [
        ("math_8a", "Mathematics 8A", 1, "difficulty"),
        ("science_8a", "Science 8A", 1, "difficulty"),
        ("english_8a", "English 8A", 1, "difficulty"),
        ("math_10a", "Mathematics 10A", 1, "difficulty"),
        ("science_10a", "Science 10A", 1, "difficulty"),
        ("english_10a", "English 10A", 1, "difficulty"),
        ("math_12a", "Mathematics 12A", 1, "bloom"),
        ("science_12a", "Science 12A", 1, "bloom"),
        ("english_12a", "English 12A", 1, "bloom"),
        ("math_8b", "Mathematics 8B", 2, "bloom"),
        ("science_8b", "Science 8B", 2, "bloom"),
        ("english_8b", "English 8B", 2, "bloom"),
        ("advisory_8a", "Advisory 8A", 2, "bloom"),
        ("advisory_10a", "Advisory 10A", 2, "bloom"),
        ("math_10b_archived", "Mathematics 10B (Archived)", 2, "bloom"),
    ];

    let mut tos_list = Vec::with_capacity(15);

    for (class_key, class_title, period, template_type) in class_names.iter() {
        let id = tos_id(&format!("{}_tos", class_key));
        let class_id = class_id(class_key);

        tos_list.push(TosSpec {
            id,
            class_id,
            period: *period,
            title: format!("TOS for {} - Q{}", class_title, period),
            template_type: template_type.to_string(),
            total_items: 30,
            time_limit_unit: "days".into(),
            ww_percent: 30.0,
            pt_percent: 50.0,
            qa_percent: 20.0,
            easy_percent: 30.0,
            average_percent: 50.0,
            difficult_percent: 20.0,
            remembering_percent: 15.0,
            understanding_percent: 20.0,
            applying_percent: 20.0,
            analyzing_percent: 15.0,
            evaluating_percent: 15.0,
            creating_percent: 15.0,
        });
    }

    tos_list
}

pub fn manual_competencies() -> Vec<CompetencySpec> {
    let class_tos_mappings = [
        ("math_8a", vec![
            ("M8AL-Ia-1", "factors completely different types of polynomials"),
            ("M8AL-Ib-1", "solves problems involving factors of polynomials"),
            ("M8AL-Ic-1", "illustrates rational algebraic expressions"),
            ("M8AL-Id-1", "performs operations on rational algebraic expressions"),
        ]),
        ("science_8a", vec![
            ("S8MT-Ia-1", "describe the arrangement of elements in the periodic table"),
            ("S8MT-Ib-1", "trace the development of the periodic table"),
            ("S8MT-Ic-1", "use the periodic table to find information about an element"),
            ("S8MT-Id-1", "describe the formation of ionic and covalent bonds"),
        ]),
        ("english_8a", vec![
            ("E8OL-Ia-1", "use appropriate listening strategies based on purpose"),
            ("E8OL-Ib-1", "employ analytical listening for information"),
            ("E8OL-Ic-1", "distinguish between fact and opinion"),
        ]),
        ("math_10a", vec![
            ("M10AL-Ia-1", "generates patterns"),
            ("M10AL-Ib-1", "illustrates an arithmetic sequence"),
            ("M10AL-Ic-1", "solves problems involving arithmetic sequences"),
            ("M10AL-Id-1", "illustrates a geometric sequence"),
        ]),
        ("science_10a", vec![
            ("S10MT-Ia-1", "explain the formation of ions"),
            ("S10MT-Ib-1", "write formulas of ionic compounds"),
            ("S10MT-Ic-1", "name ionic compounds"),
        ]),
        ("english_10a", vec![
            ("E10OL-Ia-1", "listen for important points"),
            ("E10OL-Ib-1", "note specific details"),
            ("E10OL-Ic-1", "employ correct listening strategies"),
            ("E10OL-Id-1", "assess the effectiveness of listening strategies"),
        ]),
        ("math_12a", vec![
            ("M12GM-Ia-1", "represents real-life situations using functions"),
            ("M12GM-Ib-1", "evaluates functions"),
            ("M12GM-Ic-1", "performs operations on functions"),
        ]),
        ("science_12a", vec![
            ("S12LL-Ia-1", "explain the structure and function of DNA"),
            ("S12LL-Ib-1", "explain the process of protein synthesis"),
            ("S12LL-Ic-1", "describe how mutations affect the phenotype"),
            ("S12LL-Id-1", "explain how genes are inherited"),
        ]),
        ("english_12a", vec![
            ("E12OL-Ia-1", "formulate assumptions"),
            ("E12OL-Ib-1", "analyze intentions of speakers"),
            ("E12OL-Ic-1", "assess the effectiveness of communication"),
        ]),
        ("math_8b", vec![
            ("M8AL-IIa-1", "differentiates linear inequalities from linear equations"),
            ("M8AL-IIa-2", "illustrates and graphs linear inequalities"),
            ("M8AL-IIa-3", "solves problems involving linear inequalities"),
            ("M8AL-IIb-1", "solves a system of linear inequalities"),
        ]),
        ("science_8b", vec![
            ("S8LT-IIIa-1", "explain the major stages of the cell cycle"),
            ("S8LT-IIIb-1", "describe the process of mitosis and meiosis"),
            ("S8LT-IIIc-1", "explain the different types of asexual reproduction"),
            ("S8LT-IIId-1", "describe the process of sexual reproduction"),
        ]),
        ("english_8b", vec![
            ("E8OL-IVa-1", "distinguish the types of speech context"),
            ("E8OL-IVb-1", "identifies the types of speech act"),
            ("E8OL-IVc-1", "provides appropriate responses"),
        ]),
        ("advisory_8a", vec![
            ("AD8PH-Ia-1", "demonstrates positive personal health practices"),
            ("AD8PH-Ib-1", "explains the dimensions of holistic health"),
            ("AD8PH-Ic-1", "analyzes the dimensions of holistic health"),
        ]),
        ("advisory_10a", vec![
            ("AD10PH-Ia-1", "applies decision-making skills"),
            ("AD10PH-Ib-1", "analyzes health information"),
            ("AD10PH-Ic-1", "demonstrates health appraisal skills"),
        ]),
        ("math_10b_archived", vec![
            ("M10AL-IIa-1", "illustrates polynomial functions"),
            ("M10AL-IIb-1", "graphs polynomial functions"),
            ("M10AL-IIc-1", "solves problems involving polynomial functions"),
        ]),
    ];

    let mut competencies = Vec::with_capacity(60);

    for (class_key, comp_data) in class_tos_mappings.iter() {
        let tos_id = tos_id(&format!("{}_tos", class_key));

        for (idx, (code, text)) in comp_data.iter().enumerate() {
            let comp_id = competency_id(&format!("{}_comp_{}", class_key, idx));
            let time_units = 3 + (idx as i32 % 5); // 3-7 days

            competencies.push(CompetencySpec {
                id: comp_id,
                tos_id,
                code: Some(code.to_string()),
                text: text.to_string(),
                time_units_taught: time_units,
                order: idx as i32,
            });
        }
    }

    competencies
}

pub fn manual_assessments(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(20);
    let now = ctx.now();

    // Class configs: (class_key, class_id, tos_id, period, component_base)
    let class_configs = [
        // Q1
        ("math_8a", class_id("math_8a"), tos_id("math_8a_tos"), 1, "written_work"),
        ("science_8a", class_id("science_8a"), tos_id("science_8a_tos"), 1, "written_work"),
        ("english_8a", class_id("english_8a"), tos_id("english_8a_tos"), 1, "performance_task"),
        ("math_10a", class_id("math_10a"), tos_id("math_10a_tos"), 1, "period_assessment"),
        ("science_10a", class_id("science_10a"), tos_id("science_10a_tos"), 1, "written_work"),
        ("english_10a", class_id("english_10a"), tos_id("english_10a_tos"), 1, "performance_task"),
        ("math_12a", class_id("math_12a"), tos_id("math_12a_tos"), 1, "written_work"),
        ("science_12a", class_id("science_12a"), tos_id("science_12a_tos"), 1, "period_assessment"),
        ("english_12a", class_id("english_12a"), tos_id("english_12a_tos"), 1, "performance_task"),
        // Q2
        ("math_8b", class_id("math_8b"), tos_id("math_8b_tos"), 2, "written_work"),
        ("science_8b", class_id("science_8b"), tos_id("science_8b_tos"), 2, "performance_task"),
        ("english_8b", class_id("english_8b"), tos_id("english_8b_tos"), 2, "period_assessment"),
        ("advisory_8a", class_id("advisory_8a"), tos_id("advisory_8a_tos"), 2, "written_work"),
        ("advisory_10a", class_id("advisory_10a"), tos_id("advisory_10a_tos"), 2, "performance_task"),
        ("math_10b_archived", class_id("math_10b_archived"), tos_id("math_10b_archived_tos"), 2, "written_work"),
        // Q3
        ("math_8a", class_id("math_8a"), tos_id("math_8a_tos"), 3, "written_work"),
        ("science_8a", class_id("science_8a"), tos_id("science_8a_tos"), 3, "written_work"),
        ("english_8a", class_id("english_8a"), tos_id("english_8a_tos"), 3, "performance_task"),
        ("math_10a", class_id("math_10a"), tos_id("math_10a_tos"), 3, "period_assessment"),
        ("science_10a", class_id("science_10a"), tos_id("science_10a_tos"), 3, "written_work"),
        ("english_10a", class_id("english_10a"), tos_id("english_10a_tos"), 3, "performance_task"),
        ("math_12a", class_id("math_12a"), tos_id("math_12a_tos"), 3, "written_work"),
        ("science_12a", class_id("science_12a"), tos_id("science_12a_tos"), 3, "period_assessment"),
        ("english_12a", class_id("english_12a"), tos_id("english_12a_tos"), 3, "performance_task"),
        // Q4
        ("math_8b", class_id("math_8b"), tos_id("math_8b_tos"), 4, "written_work"),
        ("science_8b", class_id("science_8b"), tos_id("science_8b_tos"), 4, "performance_task"),
        ("english_8b", class_id("english_8b"), tos_id("english_8b_tos"), 4, "period_assessment"),
        ("advisory_8a", class_id("advisory_8a"), tos_id("advisory_8a_tos"), 4, "written_work"),
        ("advisory_10a", class_id("advisory_10a"), tos_id("advisory_10a_tos"), 4, "performance_task"),
        ("math_10b_archived", class_id("math_10b_archived"), tos_id("math_10b_archived_tos"), 4, "written_work"),
    ];

    let mut assessments = Vec::with_capacity(45);
    let mut assessment_counter = 0;

    for (class_idx, (class_key, class_id, tos_id, period, _base_component)) in class_configs.iter().enumerate() {
        // 1-3 assessments per class (deterministic: 1 + class_idx % 3)
        let num_assessments = 1 + (class_idx % 3);

        for assess_idx in 0..num_assessments {
            assessment_counter += 1;
            let assess_global_idx = assessment_counter;

            // Time window: 60% closed, 30% open, 10% future
            let time_window = assess_global_idx % 10;
            let (open_at, close_at, is_closed, is_future) = match time_window {
                0..=5 => (now - chrono::Duration::days(7), now - chrono::Duration::days(1), true, false),      // Closed (60%)
                6..=8 => (now - chrono::Duration::days(1), now + chrono::Duration::days(7), false, false), // Open (30%)
                _ => (now + chrono::Duration::days(1), now + chrono::Duration::days(14), false, true),  // Future (10%)
            };

            let is_published = !is_future;
            let results_released = is_closed && is_published;

            // Question count: rotates 10/20/30 per class
            let question_count = match (class_idx + assess_idx) % 3 {
                0 => 10,
                1 => 20,
                _ => 30,
            };

            // Generate questions
            let questions = generate_questions(
                class_key,
                class_idx,
                assess_idx,
                *period,
                question_count,
            );

            let total_points: i32 = questions.iter().map(|q| q.points).sum();

            // Component rotates
            let components = ["written_work", "performance_task", "period_assessment"];
            let component = components[(class_idx + assess_idx) % 3].to_string();

            // Time limit: 30, 45, or 60 minutes
            let time_limit = 30 + ((class_idx + assess_idx) % 3) * 15;

            let assess_id = assessment_id(&format!("{}_q{}_assess_{}", class_key, period, assess_idx));

            assessments.push(AssessmentSpec {
                id: assess_id,
                class_id: *class_id,
                title: format!("Assessment {} - {} ({})", assess_idx + 1, class_key.replace('_', " "),
                    if is_closed { "Closed" } else if is_future { "Future" } else { "Open" }),
                description: Some("Seeded assessment for manual testing".into()),
                time_limit_minutes: time_limit as i32,
                open_at,
                close_at,
                show_results_immediately: component == "written_work",
                total_points,
                component,
                tos_id: *tos_id,
                created_at: created,
                deleted_at: None,
                is_published,
                results_released,
                grading_period_number: *period,
                questions,
            });
        }
    }

    // Add 1 soft-deleted assessment
    let deleted_class_id = class_id("math_8a");
    let deleted_tos_id = tos_id("math_8a_tos");
    let deleted_questions = generate_questions("math_8a", 0, 99, 1, 5);
    let deleted_total_points: i32 = deleted_questions.iter().map(|q| q.points).sum();

    assessments.push(AssessmentSpec {
        id: assessment_id("deleted_math_review"),
        class_id: deleted_class_id,
        title: "[DELETED] Review Test - Math 8A".into(),
        description: None,
        time_limit_minutes: 30,
        open_at: ctx.days_ago(8),
        close_at: ctx.days_ago(4),
        show_results_immediately: false,
        total_points: deleted_total_points,
        component: "written_work".into(),
        tos_id: deleted_tos_id,
        created_at: ctx.days_ago(15),
        deleted_at: Some(ctx.days_ago(4)),
        is_published: false,
        results_released: false,
        grading_period_number: 1,
        questions: deleted_questions,
    });

    assessments
}

/// Generate questions for an assessment
fn generate_questions(
    class_key: &str,
    class_idx: usize,
    assess_idx: usize,
    period: i32,
    count: usize,
) -> Vec<QuestionSpec> {
    let mut questions = Vec::with_capacity(count);

    // Competency IDs for this class
    let num_comps = 3 + (class_idx % 3); // 3-5 competencies
    let comp_ids: Vec<Uuid> = (0..num_comps)
        .map(|idx| competency_id(&format!("{}_comp_{}", class_key, idx)))
        .collect();

    // Question type distribution: 50% MCQ, 25% identification, 15% enumeration, 10% essay
    // But essay capped at 30% of assessments (we handle this by limiting essay count)
    let max_essays = (count as f64 * 0.10).ceil() as usize;
    let mut essay_count = 0;

    for q_idx in 0..count {
        let question_idx = class_idx * 1000 + assess_idx * 100 + q_idx;
        let q_type_idx = question_idx % 100;

        let (q_type, has_choices, acceptable_answers) = if q_type_idx < 50 {
            ("multiple_choice", true, vec!["A".into()]) // 50% MCQ
        } else if q_type_idx < 75 {
            ("identification", false, vec!["answer".into(), "alt".into()]) // 25% identification
        } else if q_type_idx < 90 && essay_count < max_essays {
            essay_count += 1;
            ("essay", false, vec![]) // 10% essay (capped)
        } else {
            ("enumeration", false, vec!["item1".into(), "item2".into(), "item3".into()]) // 15% enumeration
        };

        // Difficulty rotates
        let difficulties = ["easy", "medium", "hard"];
        let difficulty = difficulties[q_idx % 3];

        // Cognitive level rotates
        let cognitive_levels = ["remembering", "understanding", "applying", "analyzing", "evaluating", "creating"];
        let cognitive_level = cognitive_levels[q_idx % 6];

        // Points: 1, 2, or 5
        let points = if q_type == "essay" { 5 } else if difficulty == "hard" { 2 } else { 1 };

        // Competency assignment
        let tos_competency_id = comp_ids.get(q_idx % comp_ids.len()).copied();

        let q_id = question_id(&format!("{}_q{}_assess_{}", class_key, period, assess_idx), q_idx as u32);

        // Generate choices for MCQ
        let choices = if has_choices {
            let q_id_str = format!("{}_q{}_assess_{}_q{}", class_key, period, assess_idx, q_idx);
            vec![
                ChoiceSpec { id: choice_id(&q_id_str, 0), text: "Option A".into(), is_correct: true, order: 0 },
                ChoiceSpec { id: choice_id(&q_id_str, 1), text: "Option B".into(), is_correct: false, order: 1 },
                ChoiceSpec { id: choice_id(&q_id_str, 2), text: "Option C".into(), is_correct: false, order: 2 },
                ChoiceSpec { id: choice_id(&q_id_str, 3), text: "Option D".into(), is_correct: false, order: 3 },
            ]
        } else {
            vec![]
        };

        questions.push(QuestionSpec {
            id: q_id,
            question_type: q_type.into(),
            text: format!("Question {} for {}", q_idx + 1, class_key.replace('_', " ")),
            points,
            order: q_idx as i32,
            is_multi_select: false,
            tos_competency_id,
            difficulty: Some(difficulty.into()),
            cognitive_level: Some(cognitive_level.into()),
            choices,
            answer_key: AnswerKeySpec { acceptable_answers },
        });
    }

    questions
}

pub fn manual_assignments(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);

    // Class configs: (class_key, class_id, period)
    let class_configs = [
        // Q1
        ("math_8a", class_id("math_8a"), 1),
        ("science_8a", class_id("science_8a"), 1),
        ("english_8a", class_id("english_8a"), 1),
        ("math_10a", class_id("math_10a"), 1),
        ("science_10a", class_id("science_10a"), 1),
        ("english_10a", class_id("english_10a"), 1),
        ("math_12a", class_id("math_12a"), 1),
        ("science_12a", class_id("science_12a"), 1),
        ("english_12a", class_id("english_12a"), 1),
        // Q2
        ("math_8b", class_id("math_8b"), 2),
        ("science_8b", class_id("science_8b"), 2),
        ("english_8b", class_id("english_8b"), 2),
        ("advisory_8a", class_id("advisory_8a"), 2),
        ("advisory_10a", class_id("advisory_10a"), 2),
        ("math_10b_archived", class_id("math_10b_archived"), 2),
        // Q3
        ("math_8a", class_id("math_8a"), 3),
        ("science_8a", class_id("science_8a"), 3),
        ("english_8a", class_id("english_8a"), 3),
        ("math_10a", class_id("math_10a"), 3),
        ("science_10a", class_id("science_10a"), 3),
        ("english_10a", class_id("english_10a"), 3),
        ("math_12a", class_id("math_12a"), 3),
        ("science_12a", class_id("science_12a"), 3),
        ("english_12a", class_id("english_12a"), 3),
        // Q4
        ("math_8b", class_id("math_8b"), 4),
        ("science_8b", class_id("science_8b"), 4),
        ("english_8b", class_id("english_8b"), 4),
        ("advisory_8a", class_id("advisory_8a"), 4),
        ("advisory_10a", class_id("advisory_10a"), 4),
        ("math_10b_archived", class_id("math_10b_archived"), 4),
    ];

    let mut assignments = Vec::with_capacity(45);
    let mut assignment_counter = 0;

    for (class_idx, (class_key, class_id, period)) in class_configs.iter().enumerate() {
        // 1-3 assignments per class
        let num_assignments = 1 + (class_idx % 3);

        for assign_idx in 0..num_assignments {
            assignment_counter += 1;
            let assign_global_idx = assignment_counter;

            // Due dates: 40% past, 40% soon, 20% future
            let due_date = match assign_global_idx % 10 {
                0..=3 => ctx.days_ago(5),          // Past due (40%)
                4..=7 => ctx.days_from_now(2),      // Due soon (40%)
                _ => ctx.days_from_now(14),        // Future (20%)
            };

            // Component rotates
            let components = ["written_work", "performance_task"];
            let component = components[(class_idx + assign_idx) % 2].to_string();

            // Points: 10, 20, or 50
            let points = match (class_idx + assign_idx) % 3 {
                0 => 10,
                1 => 20,
                _ => 50,
            };

            let assign_id = assignment_id(&format!("{}_q{}_assign_{}", class_key, period, assign_idx));

            assignments.push(AssignmentSpec {
                id: assign_id,
                class_id: *class_id,
                title: format!("Assignment {} - {}", assign_idx + 1, class_key.replace('_', " ")),
                instructions: "Submit your answer as plain text.".into(),
                total_points: points,
                allows_text_submission: true,
                allows_file_submission: false,
                due_at: due_date,
                component,
                created_at: created,
                deleted_at: None,
                is_published: true,
                grading_period_number: *period,
            });
        }
    }

    // Add 1 soft-deleted assignment (in Math 8A as per spec)
    assignments.push(AssignmentSpec {
        id: assignment_id("deleted_homework_math_8a"),
        class_id: class_id("math_8a"),
        title: "[DELETED] Homework 3 - Math 8A".into(),
        instructions: "Submit your answer as plain text.".into(),
        total_points: 20,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: ctx.days_ago(5),
        component: "written_work".into(),
        created_at: ctx.days_ago(15),
        deleted_at: Some(ctx.days_ago(3)),
        is_published: false,
        grading_period_number: 1,
    });

    assignments
}

pub fn manual_materials(ctx: &SeedContext) -> Vec<MaterialSpec> {
    let created = ctx.days_ago(20);

    let class_configs = [
        ("math_8a", class_id("math_8a")),
        ("science_8a", class_id("science_8a")),
        ("english_8a", class_id("english_8a")),
        ("math_10a", class_id("math_10a")),
        ("science_10a", class_id("science_10a")),
        ("english_10a", class_id("english_10a")),
        ("math_12a", class_id("math_12a")),
        ("science_12a", class_id("science_12a")),
        ("english_12a", class_id("english_12a")),
        ("math_8b", class_id("math_8b")),
        ("science_8b", class_id("science_8b")),
        ("english_8b", class_id("english_8b")),
        ("advisory_8a", class_id("advisory_8a")),
        ("advisory_10a", class_id("advisory_10a")),
        ("math_10b_archived", class_id("math_10b_archived")),
    ];

    let topics = [
        "Introduction",
        "Fundamental Concepts",
        "Advanced Topics",
    ];

    let lorem_content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.";

    let mut materials = Vec::with_capacity(45);

    for (class_key, class_id) in &class_configs {
        for mat_idx in 0..3 {
            let mat_id = material_id(&format!("{}_mat_{}", class_key, mat_idx));

            materials.push(MaterialSpec {
                id: mat_id,
                class_id: *class_id,
                title: format!("Unit {}: {}", mat_idx + 1, topics[mat_idx]),
                description: Some("Seeded material for manual testing.".into()),
                content_text: Some(lorem_content.into()),
                order_index: mat_idx as i32,
                created_at: created,
            });
        }
    }

    materials
}

pub fn manual_school_settings(_ctx: &SeedContext) -> SchoolSettingsSpec {
    let school_code = std::env::var("SCHOOL_CODE").unwrap_or_else(|_| "SEED-SCHOOL".to_string());
    SchoolSettingsSpec {
        id: 1,
        school_code,
        school_name: Some("Likha Test School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        school_district: None,
        school_head_name: Some("Dr. Juan Dela Cruz".into()),
        school_head_position: Some("Principal II".into()),
        updated_at: _ctx.now(),
    }
}

pub fn manual_learner_details() -> Vec<LearnerDetailsSpec> {
    let mut details = Vec::with_capacity(70);

    for i in 1..=70 {
        let username = student_username(i);
        let lrn = format!("136-1234-{:03}", i);
        let age = (15 + (i % 3)) as i32; // Ages 15-17
        let sex = if i % 2 == 0 { "Female" } else { "Male" };
        let tracks = ["STEM", "ABM", "HUMSS"];
        let track = tracks[(i as usize) % 3];
        let curriculum = "K to 12";

        details.push(LearnerDetailsSpec {
            id: seed_id("learner_details", &username),
            user_id: user_id(&username),
            lrn: Some(lrn),
            age: Some(age),
            sex: Some(sex.into()),
            track_strand: Some(track.into()),
            curriculum: Some(curriculum.into()),
        });
    }

    details
}
