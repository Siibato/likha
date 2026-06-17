//! Quarter 3 assignments for realistic seeding.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn realistic_assignments_q3(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(98);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("eng_q3_assign1"), class_id: cid("english_9a"),
            title: "Research Paper: Effects of Social Media on Students".into(),
            instructions: "Write a 300-word research paper on how social media affects students' academic performance. Include at least two credible sources and proper citations in MLA format.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(78), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
        AssignmentSpec {
            id: asid("eng_q3_assign2"), class_id: cid("english_9a"),
            title: "Multimedia Presentation: Media Literacy Campaign".into(),
            instructions: "Create a multimedia presentation (slides with text and images) promoting media literacy among teenagers. Include at least 5 slides with persuasive techniques and call-to-action.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(75), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
        AssignmentSpec {
            id: asid("sci_q3_assign1"), class_id: cid("science_9a"),
            title: "Problem Set: Newton's Laws Applications".into(),
            instructions: "Solve 5 word problems applying Newton's three laws of motion. Show your calculations and explain the physical principles involved in each problem.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(76), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
        AssignmentSpec {
            id: asid("sci_q3_assign2"), class_id: cid("science_9a"),
            title: "Lab Report: Energy Transformation in a Pendulum".into(),
            instructions: "Conduct an experiment with a simple pendulum. Record measurements of height and speed at different points. Calculate kinetic and potential energy at each point and write a 200-word analysis of energy conservation.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(73), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
        AssignmentSpec {
            id: asid("adv_q3_assign1"), class_id: cid("advisory_9a"),
            title: "Role-Play Script: Assertive Communication".into(),
            instructions: "Write a 200-word dialogue script showing assertive communication in a peer pressure situation. Include the scenario, assertive response, and expected outcome.".into(),
            total_points: 30, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(74), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 3,
        },
    ]
}
