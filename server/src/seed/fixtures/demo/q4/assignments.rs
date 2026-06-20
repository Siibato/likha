//! Q4 assignments for demo seeding: Physics.

use crate::seed::specs::AssignmentSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn demo_assignments_q4(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("q4_assign1"), class_id: cid("sci10"),
            title: "Essay: Newton's Laws in Everyday Life".into(),
            instructions: "Explain Newton's three laws of motion and give one real-world example for each law. Write 2-3 paragraphs showing how these laws apply to activities you do every day.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(5), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
        AssignmentSpec {
            id: asid("q4_assign2"), class_id: cid("sci10"),
            title: "Short Answer: Energy and Simple Machines".into(),
            instructions: "Answer the following questions in 1-2 sentences each: (1) What is the difference between kinetic and potential energy? (2) How do simple machines make work easier? (3) Name two simple machines commonly used in Philippine households or farms.".into(),
            total_points: 25, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(3), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
    ]
}
