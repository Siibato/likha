//! T2 assignments for demo-2: 6 subjects × 2 assignments each (12 total).

use super::super::{asid, cid};
use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_assignments_t2(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(13);
    let now = ctx.now();
    let mut assignments = Vec::with_capacity(12);

    // Science 10 - Genetics
    assignments.push(AssignmentSpec {
        id: asid("sci_t2_assign1"),
        class_id: cid("sci10"),
        title: "Essay: Mendel's Laws and Human Inheritance".into(),
        instructions: "Explain how Mendel's laws apply to human inheritance. Choose a specific human trait and describe how it is passed from parents to offspring according to Mendelian patterns. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });
    assignments.push(AssignmentSpec {
        id: asid("sci_t2_assign2"),
        class_id: cid("sci10"),
        title: "Short Answer: DNA and Protein Synthesis".into(),
        instructions: "Answer in 1-2 sentences each: (1) What is the structure of DNA? (2) What happens during transcription? (3) What is the role of mRNA in protein synthesis?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });

    // English 10 - World Literature
    assignments.push(AssignmentSpec {
        id: asid("eng_t2_assign1"),
        class_id: cid("eng10"),
        title: "Essay: Literature as Mirror of Life".into(),
        instructions: "Analyze how a 21st century literary work reflects contemporary global issues. Use specific examples from a work you have studied to support your analysis. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });
    assignments.push(AssignmentSpec {
        id: asid("eng_t2_assign2"),
        class_id: cid("eng10"),
        title: "Short Response: Text and Context".into(),
        instructions: "Explain how understanding the cultural and historical context of a literary work enhances its meaning. Give a specific example from a work you have read.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });

    // Math 10 - Quadratic Functions
    assignments.push(AssignmentSpec {
        id: asid("math_t2_assign1"),
        class_id: cid("math10"),
        title: "Problem Set: Quadratic Functions".into(),
        instructions: "Solve: (1) Find the vertex of y = x² - 4x + 3. (2) Convert y = 2(x-1)² + 3 to standard form. (3) Determine if the parabola y = -x² + 2x + 1 opens up or down and explain why.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });
    assignments.push(AssignmentSpec {
        id: asid("math_t2_assign2"),
        class_id: cid("math10"),
        title: "Word Problems: Quadratic Applications".into(),
        instructions: "Solve: (1) The area of a rectangle is 48 sq units. If the length is 4 units more than the width, find the dimensions. (2) A ball is thrown upward with height h(t) = -5t² + 20t. Find maximum height.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });

    // AP 10 - Revolution & American Period
    assignments.push(AssignmentSpec {
        id: asid("ap_t2_assign1"),
        class_id: cid("ap10"),
        title: "Essay: Causes of the Philippine Revolution".into(),
        instructions: "Analyze the causes and consequences of the Philippine Revolution. Discuss the key events and figures that shaped this period. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });
    assignments.push(AssignmentSpec {
        id: asid("ap_t2_assign2"),
        class_id: cid("ap10"),
        title: "Short Answer: American Colonial Impact".into(),
        instructions: "Answer in 1-2 sentences each: (1) What was the impact of American education? (2) What was the significance of the Jones Law? (3) How did the Commonwealth period prepare for independence?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });

    // Filipino 10 - Tula at Dula
    assignments.push(AssignmentSpec {
        id: asid("fil_t2_assign1"),
        class_id: cid("fil10"),
        title: "Sanaysay: Gamit ng Tayutay sa Tula".into(),
        instructions: "Suriin ang gamit ng mga tayutay sa isang tula. Paano nakatulong ang mga ito sa pagpapahayag ng mensahe ng tula? Isulat ang 2-3 talata.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });
    assignments.push(AssignmentSpec {
        id: asid("fil_t2_assign2"),
        class_id: cid("fil10"),
        title: "Maikling Tugon: Tula at Dula".into(),
        instructions: "Ihambing ang isang tula at isang dula. Ano ang pagkakatulad at pagkakaiba ng mga ito sa pagpapahayag ng tema?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });

    // TLE 10 - Cookery
    assignments.push(AssignmentSpec {
        id: asid("tle_t2_assign1"),
        class_id: cid("tle10"),
        title: "Lab Report: Egg Dish Preparation".into(),
        instructions: "Document the step-by-step process of preparing a vegetable omelet. Include knife skills, cooking techniques, and safety precautions. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });
    assignments.push(AssignmentSpec {
        id: asid("tle_t2_assign2"),
        class_id: cid("tle10"),
        title: "Short Answer: Food Safety".into(),
        instructions: "Answer in 1-2 sentences each: (1) What is the danger zone for food? (2) What is cross-contamination? (3) Why is proper hand washing important in food preparation?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 2,
    });

    assignments
}
