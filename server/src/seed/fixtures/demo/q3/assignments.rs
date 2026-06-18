//! Q3 assignments for demo seeding: Chemistry.

use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn demo_assignments_q3(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("q3_assign1"), class_id: cid("sci10"),
            title: "Essay: Ionic vs Covalent Compounds".into(),
            instructions: "Compare ionic and covalent compounds. Write 2-3 paragraphs explaining the differences in bonding, properties, and real-world examples of each.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(5), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
        AssignmentSpec {
            id: asid("q3_assign2"), class_id: cid("sci10"),
            title: "Short Answer: Balancing Chemical Equations".into(),
            instructions: "Answer the following questions in 1-2 sentences each: (1) Why must chemical equations be balanced? (2) What does a coefficient tell you? (3) Give one example of a balanced equation from everyday life.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(3), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
    ]
}
