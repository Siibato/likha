//! Demo-2 classes: 1 Advisory + 6 subjects.

use super::super::cid;
use crate::seed::specs::ClassSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    let created = ctx.days_ago(25);
    vec![
        ClassSpec {
            id: cid("adv_mahogany"),
            title: "Grade 10 - Mahogany".into(),
            description: Some("Grade 10 Advisory class - Mahogany section".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: true,
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
            title: "Grade 10 - Mathematics".into(),
            description: Some("Grade 10 Mathematics class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: cid("ap10"),
            title: "Grade 10 - Araling Panlipunan".into(),
            description: Some("Grade 10 Araling Panlipunan class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: cid("fil10"),
            title: "Grade 10 - Filipino".into(),
            description: Some("Grade 10 Filipino class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        ClassSpec {
            id: cid("tle10"),
            title: "Grade 10 - TLE".into(),
            description: Some("Grade 10 TLE class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
    ]
}
