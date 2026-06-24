//! T3 assignments for demo-2: 6 subjects × 2 assignments each (12 total).

use super::super::{asid, cid};
use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_assignments_t3(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(8);
    let now = ctx.now();
    let mut assignments = Vec::with_capacity(12);

    // Science 10 - Chemistry
    assignments.push(AssignmentSpec {
        id: asid("sci_t3_assign1"),
        class_id: cid("sci10"),
        title: "Essay: Chemical Bonds in Everyday Life".into(),
        instructions: "Explain how atoms form chemical bonds and why different types of bonds form between different elements. Use specific examples from everyday life (e.g., table salt, water, metals). Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });
    assignments.push(AssignmentSpec {
        id: asid("sci_t3_assign2"),
        class_id: cid("sci10"),
        title: "Short Answer: Chemical Reactions".into(),
        instructions: "Answer in 1-2 sentences each: (1) What is the difference between synthesis and decomposition reactions? (2) Give an example of a combustion reaction. (3) How do chemical reactions relate to everyday phenomena like cooking or rusting?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });

    // English 10 - Academic Writing
    assignments.push(AssignmentSpec {
        id: asid("eng_t3_assign1"),
        class_id: cid("eng10"),
        title: "Position Paper: Current Community Issue".into(),
        instructions: "Write a position paper on a current issue affecting your community. Include a clear thesis statement, supporting evidence, and address counterarguments. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });
    assignments.push(AssignmentSpec {
        id: asid("eng_t3_assign2"),
        class_id: cid("eng10"),
        title: "Short Response: Citation and Plagiarism".into(),
        instructions: "Explain the importance of proper citation in academic writing. Discuss the consequences of plagiarism and describe how to avoid it using proper citation practices.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });

    // Math 10 - Geometry
    assignments.push(AssignmentSpec {
        id: asid("math_t3_assign1"),
        class_id: cid("math10"),
        title: "Problem Set: Geometric Sequences".into(),
        instructions: "Solve: (1) Find the sum of the first 10 terms of the geometric sequence 2, 6, 18, 54, ... (2) A bacteria culture doubles every hour. If it starts with 100 bacteria, how many will there be after 6 hours? (3) Find the 8th term of 5, 15, 45, ...".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });
    assignments.push(AssignmentSpec {
        id: asid("math_t3_assign2"),
        class_id: cid("math10"),
        title: "Word Problems: Geometric Applications".into(),
        instructions: "Solve: (1) A car depreciates by 15% each year. If it costs $20,000 new, what is its value after 5 years? (2) An investment grows by 8% annually. If you invest $5,000, how much will you have after 4 years?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });

    // AP 10 - Contemporary PH History
    assignments.push(AssignmentSpec {
        id: asid("ap_t3_assign1"),
        class_id: cid("ap10"),
        title: "Essay: Impact of Martial Law".into(),
        instructions: "Analyze the impact of Martial Law on Philippine society and democracy. Discuss both the immediate effects and long-term consequences. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });
    assignments.push(AssignmentSpec {
        id: asid("ap_t3_assign2"),
        class_id: cid("ap10"),
        title: "Short Answer: Contemporary Issues".into(),
        instructions: "Answer in 1-2 sentences each: (1) What are the main contemporary challenges facing the Philippines? (2) How can history guide future decisions? (3) What is the role of youth in nation-building?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });

    // Filipino 10 - Sanaysay at Komunikasyon
    assignments.push(AssignmentSpec {
        id: asid("fil_t3_assign1"),
        class_id: cid("fil10"),
        title: "Sanaysay: Isyu sa Komunidad".into(),
        instructions: "Sulat ang isang position paper tungkol sa isang isyu sa iyong komunidad. Maglagay ng malin na thesis, ebidensya, at counterarguments. Isulat ang 2-3 talata.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });
    assignments.push(AssignmentSpec {
        id: asid("fil_t3_assign2"),
        class_id: cid("fil10"),
        title: "Maikling Tugon: Komunikasyon at Integridad".into(),
        instructions: "Ipaliwanag ang kahalagahan ng wastong komunikasyon at akademikong integridad. Tukuyin ang mga konsekwensya ng plagiarism at paano iwasan ito.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });

    // TLE 10 - Entrepreneurship
    assignments.push(AssignmentSpec {
        id: asid("tle_t3_assign1"),
        class_id: cid("tle10"),
        title: "Business Plan: Small Business Idea".into(),
        instructions: "Develop a simple business plan for a small business idea in your community. Include the business concept, target market, and basic financial projections. Write 2-3 paragraphs.".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(5),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });
    assignments.push(AssignmentSpec {
        id: asid("tle_t3_assign2"),
        class_id: cid("tle10"),
        title: "Short Answer: Financial Management".into(),
        instructions: "Answer in 1-2 sentences each: (1) What is the importance of bookkeeping for small businesses? (2) What are the risks of poor financial management? (3) How does proper pricing affect business success?".into(),
        total_points: 25,
        allows_text_submission: true,
        allows_file_submission: false,
        due_at: now - chrono::Duration::days(3),
        component: "performance_task".into(),
        created_at: created,
        deleted_at: None,
        is_published: true,
        term_number: 3,
    });

    assignments
}
