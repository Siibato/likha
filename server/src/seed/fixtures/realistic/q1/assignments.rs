//! Quarter 1 assignments for realistic seeding.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn realistic_assignments_q1(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(18);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("eng_assign1"), class_id: cid("english_9a"),
            title: "Persuasive Essay: Importance of Reading Literature".into(),
            instructions: "Write a 3-paragraph persuasive essay (150-200 words) arguing why students should read literature from African and Asian cultures. Include at least one specific example of a text we discussed in class.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(5), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("eng_assign2"), class_id: cid("english_9a"),
            title: "Character Analysis: Describe a Hero from an Afro-Asian Epic".into(),
            instructions: "Choose one hero from an Afro-Asian epic we studied (e.g., Beowulf, Gilgamesh, or Biag ni Lam-ang). Write a 200-word analysis describing three heroic qualities and provide evidence from the text.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now + chrono::Duration::days(2), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("sci_assign1"), class_id: cid("science_9a"),
            title: "Lab Report: Observing Chemical Reactions".into(),
            instructions: "Write a formal lab report describing the chemical reaction observed in the class demonstration. Include: (1) Objective, (2) Materials used, (3) Procedure, (4) Observations, (5) Conclusion with the balanced chemical equation.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(3), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
        AssignmentSpec {
            id: asid("sci_assign2"), class_id: cid("science_9a"),
            title: "Research Summary: Plate Tectonics in the Philippines".into(),
            instructions: "Research one major Philippine fault line or volcanic area. Write a 200-word summary explaining its geological cause (using plate tectonics theory), its location, and its potential impact on nearby communities.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now + chrono::Duration::days(5), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, grading_period_number: 1,
        },
    ]
}
