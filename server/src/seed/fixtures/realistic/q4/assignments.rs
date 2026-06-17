//! Quarter 4 assignments for realistic seeding.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn realistic_assignments_q4(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(138);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("eng_q4_assign1"), class_id: cid("english_9a"),
            title: "Short Story: A Lesson Learned".into(),
            instructions: "Write a 250-word short story with a clear plot structure (exposition, rising action, climax, falling action, resolution). The story should teach a moral lesson relevant to teenagers.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(118), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
        AssignmentSpec {
            id: asid("eng_q4_assign2"), class_id: cid("english_9a"),
            title: "Critical Review: Contemporary Filipino Novel".into(),
            instructions: "Write a 300-word critical review of a contemporary Filipino novel you have read. Analyze the themes, character development, and writing style. Include your personal recommendation.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(115), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
        AssignmentSpec {
            id: asid("sci_q4_assign1"), class_id: cid("science_9a"),
            title: "Circuit Analysis: Series vs Parallel".into(),
            instructions: "Draw and label both a series circuit and a parallel circuit with 3 resistors each. Calculate total resistance for both circuits. Write a 150-word comparison of their characteristics.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(116), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
        AssignmentSpec {
            id: asid("sci_q4_assign2"), class_id: cid("science_9a"),
            title: "Action Plan: Climate Change Mitigation".into(),
            instructions: "Research and propose a school-wide action plan to reduce carbon footprint. Include specific strategies for energy conservation, waste reduction, and transportation. Write a 200-word proposal with implementation steps.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(113), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
        AssignmentSpec {
            id: asid("adv_q4_assign1"), class_id: cid("advisory_9a"),
            title: "Career Portfolio: My Future Path".into(),
            instructions: "Create a career portfolio including: (1) self-assessment of skills and interests, (2) three potential career paths with descriptions, (3) education requirements for each, and (4) a 150-word reflection on your top choice.".into(),
            total_points: 30, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(114), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 4,
        },
    ]
}
