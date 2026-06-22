//! Term 2 assignments for realistic seeding.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, asid};

pub fn realistic_assignments_t2(ctx: &SeedContext) -> Vec<AssignmentSpec> {
    let created = ctx.days_ago(58);
    let now = ctx.now();
    vec![
        AssignmentSpec {
            id: asid("eng_t2_assign1"), class_id: cid("english_9a"),
            title: "Speech Script: Introduction of a Guest Speaker".into(),
            instructions: "Write a 200-word speech of introduction for a guest speaker who will talk about environmental conservation. Include appropriate greetings, background information, and a warm welcome.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(38), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, term_number: 2,
        },
        AssignmentSpec {
            id: asid("eng_t2_assign2"), class_id: cid("english_9a"),
            title: "Persuasive Speech: Promoting School Recycling Program".into(),
            instructions: "Write a 250-word persuasive speech convincing the school administration to implement a recycling program. Use at least three rhetorical devices (ethos, pathos, logos).".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(35), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, term_number: 2,
        },
        AssignmentSpec {
            id: asid("sci_t2_assign1"), class_id: cid("science_9a"),
            title: "Ecosystem Diagram: Local Community".into(),
            instructions: "Draw and label a food web showing organisms in your local community. Identify at least 5 producers, 3 consumers, and 2 decomposers. Explain the energy flow in 150 words.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(36), component: "written_work".into(),
            created_at: created, deleted_at: None, is_published: true, term_number: 2,
        },
        AssignmentSpec {
            id: asid("sci_t2_assign2"), class_id: cid("science_9a"),
            title: "Research Project: Philippine Endangered Species".into(),
            instructions: "Research one endangered species in the Philippines. Write a 200-word report covering: (1) habitat, (2) reasons for endangerment, (3) conservation efforts, and (4) your proposed solutions.".into(),
            total_points: 50, allows_text_submission: true, allows_file_submission: false,
            due_at: now - chrono::Duration::days(33), component: "performance_task".into(),
            created_at: created, deleted_at: None, is_published: true, term_number: 2,
        },
    ]
}
