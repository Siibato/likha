//! Q1 assignments for demo seeding: Plate Tectonics.

use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn demo_assignments_q1(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("q1_assign1"), class_id: cid("sci10"),
            title: "Essay: Plate Tectonics and Mountain Formation".into(),
            instructions: "Explain how plate tectonics theory explains the formation of mountains. Write 2-3 paragraphs describing the process and giving one real-world example.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(5), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, term_number: 1,
        },
        AssignmentSpec {
            id: asid("q1_assign2"), class_id: cid("sci10"),
            title: "Short Answer: Earth's Interior".into(),
            instructions: "Answer the following questions in 1-2 sentences each: (1) What is the Earth's crust made of? (2) How is the mantle different from the core? (3) What evidence do scientists use to study Earth's interior?".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(3), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, term_number: 1,
        },
    ]
}
