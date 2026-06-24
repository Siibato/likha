//! T1 assignments for demo-2: 6 subjects × 2 assignments each (12 total).

use super::super::{asid, cid};
use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_assignments_t1(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    let mut assignments = Vec::with_capacity(12);

    // Science 10
    assignments.push(AssignmentSpec {
        id: asid("sci_t1_assign1"),
        class_id: cid("sci10"),
        title: "Essay: Plate Tectonics and Mountain Formation".into(),
        instructions: "Explain how plate tectonics theory explains the formation of mountains. Write 2-3 paragraphs describing the process and giving one real-world example.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });
    assignments.push(AssignmentSpec {
        id: asid("sci_t1_assign2"),
        class_id: cid("sci10"),
        title: "Short Answer: Earth's Interior".into(),
        instructions: "Answer the following questions in 1-2 sentences each: (1) What is the Earth's crust made of? (2) How is the mantle different from the core? (3) What evidence do scientists use to study Earth's interior?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });

    // English 10
    assignments.push(AssignmentSpec {
        id: asid("eng_t1_assign1"),
        class_id: cid("eng10"),
        title: "Essay: Theme in Philippine Literature".into(),
        instructions: "Choose a Philippine short story you have read and analyze its theme. Write 2-3 paragraphs explaining how the author develops the theme through characters, setting, and plot.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });
    assignments.push(AssignmentSpec {
        id: asid("eng_t1_assign2"),
        class_id: cid("eng10"),
        title: "Short Response: Literary Devices".into(),
        instructions: "Identify and explain three literary devices used in a Filipino poem. For each device, provide an example from the poem and explain its effect.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });

    // Math 10
    assignments.push(AssignmentSpec {
        id: asid("math_t1_assign1"),
        class_id: cid("math10"),
        title: "Problem Set: Linear Equations".into(),
        instructions: "Solve the following problems: (1) Find the slope and y-intercept of y = 3x - 7. (2) Write the equation of a line passing through (2,5) with slope -2. (3) Graph the line 2x + y = 4 and identify its intercepts.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });
    assignments.push(AssignmentSpec {
        id: asid("math_t1_assign2"),
        class_id: cid("math10"),
        title: "Word Problems: Systems of Equations".into(),
        instructions: "Solve these word problems using systems of equations: (1) The sum of two numbers is 15 and their difference is 3. Find the numbers. (2) A store sells pens for $2 and notebooks for $5. If 20 items were sold for $70, how many of each were sold?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });

    // AP 10
    assignments.push(AssignmentSpec {
        id: asid("ap_t1_assign1"),
        class_id: cid("ap10"),
        title: "Essay: Pre-colonial Society".into(),
        instructions: "Describe the political and social structure of pre-colonial Philippine society. Include the role of the datu, the social classes, and the system of government. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });
    assignments.push(AssignmentSpec {
        id: asid("ap_t1_assign2"),
        class_id: cid("ap10"),
        title: "Short Answer: Spanish Colonial System".into(),
        instructions: "Answer in 1-2 sentences each: (1) What was the encomienda system? (2) What was the role of the Catholic Church during Spanish colonization? (3) How did the galleon trade affect the Philippine economy?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });

    // Filipino 10
    assignments.push(AssignmentSpec {
        id: asid("fil_t1_assign1"),
        class_id: cid("fil10"),
        title: "Sanaysay: Tema ng Maikling Kwento".into(),
        instructions: "Pumili ng isang maikling kwentong binasa mo at suriin ang tema nito. Isulat ang 2-3 talata na nagpapaliwanag kung paano binuo ng may-akda ang tema sa pamamagitan ng tauhan, tagpuan, at plot.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });
    assignments.push(AssignmentSpec {
        id: asid("fil_t1_assign2"),
        class_id: cid("fil10"),
        title: "Maikling Tugon: Mga Elemento ng Panitikan".into(),
        instructions: "Tukoy at ipaliwanag ang tatlong elemento ng panitikan na ginamit sa isang tula. Para sa bawat elemento, magbigay ng halimbawa mula sa tula at ipaliwanag ang epekto nito.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });

    // TLE 10
    assignments.push(AssignmentSpec {
        id: asid("tle_t1_assign1"),
        class_id: cid("tle10"),
        title: "Lab Report: Computer Assembly".into(),
        instructions: "Document the step-by-step process of assembling a computer from components. Include safety precautions, tools used, and any challenges encountered. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });
    assignments.push(AssignmentSpec {
        id: asid("tle_t1_assign2"),
        class_id: cid("tle10"),
        title: "Short Answer: Computer Components".into(),
        instructions: "Answer in 1-2 sentences each: (1) What is the function of the CPU? (2) What is the difference between RAM and ROM? (3) Why is thermal paste important when installing a CPU?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 1,
    });

    assignments
}
