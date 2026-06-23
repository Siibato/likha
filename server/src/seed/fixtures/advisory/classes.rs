//! Advisory classes: English 10, Math 10, Science 10 (graded) + Advisory 10 (non-graded).

use crate::seed::specs::ClassSpec;
use crate::seed::tools::{seed_id, SeedContext};

pub fn cid(key: &str) -> uuid::Uuid {
    seed_id("classes", key)
}

pub fn advisory_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    let created = ctx.days_ago(25);
    vec![
        ClassSpec {
            id: cid("eng10"),
            title: "Grade 10 - English".into(),
            description: Some("Grade 10 English class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: cid("math10"),
            title: "Grade 10 - Math".into(),
            description: Some("Grade 10 Math class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: cid("sci10"),
            title: "Grade 10 - Science".into(),
            description: Some("Grade 10 Science class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: cid("adv10"),
            title: "Advisory 10".into(),
            description: Some("Grade 10 Advisory class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: true,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
    ]
}
