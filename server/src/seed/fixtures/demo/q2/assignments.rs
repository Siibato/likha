//! Q2 assignments for demo seeding: Genetics & Heredity.

use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn demo_assignments_q2(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("q2_assign1"), class_id: cid("sci10"),
            title: "Essay: The Importance of DNA in Heredity".into(),
            instructions: "Explain the structure and function of DNA and how it carries genetic information from parents to offspring. Write 2-3 paragraphs with one specific example of how DNA determines a trait.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(5), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 2,
        },
        AssignmentSpec {
            id: asid("q2_assign2"), class_id: cid("sci10"),
            title: "Short Answer: Mendel's Laws".into(),
            instructions: "Answer the following questions in 1-2 sentences each: (1) What is the Law of Segregation? (2) What is the Law of Independent Assortment? (3) Give one real-life example of dominant and recessive inheritance in humans.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(3), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 2,
        },
    ]
}
