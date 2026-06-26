//! Demo-2 classes: 1 Advisory + 2 subjects (Science, Math).

use super::super::cid;
use crate::seed::specs::ClassSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_classes(ctx: &SeedContext) -> Vec<ClassSpec> {
    let created = ctx.days_ago(25);
    vec![
        ClassSpec {
            id: cid("adv_mahogany"),
            title: "Mahogany".into(),
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
            title: "Science".into(),
            description: Some("Science class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // English 10 - disconnected from seed
        // ClassSpec {
        //     id: cid("eng10"),
        //     title: "English".into(),
        //     description: Some("English class".into()),
        //     grade_level: Some("10".into()),
        //     school_year: Some("2025-2026".into()),
        //     is_advisory: false,
        //     is_archived: false,
        //     created_at: created,
        //     deleted_at: None,
        // },
        ClassSpec {
            id: cid("math10"),
            title: "Mathematics".into(),
            description: Some("Mathematics class".into()),
            grade_level: Some("10".into()),
            school_year: Some("2025-2026".into()),
            is_advisory: false,
            is_archived: false,
            created_at: created,
            deleted_at: None,
        },
        // AP 10 - disconnected from seed
        // ClassSpec {
        //     id: cid("ap10"),
        //     title: "Araling Panlipunan".into(),
        //     description: Some("Araling Panlipunan class".into()),
        //     grade_level: Some("10".into()),
        //     school_year: Some("2025-2026".into()),
        //     is_advisory: false,
        //     is_archived: false,
        //     created_at: created,
        //     deleted_at: None,
        // },
        // Filipino 10 - disconnected from seed
        // ClassSpec {
        //     id: cid("fil10"),
        //     title: "Filipino".into(),
        //     description: Some("Filipino class".into()),
        //     grade_level: Some("10".into()),
        //     school_year: Some("2025-2026".into()),
        //     is_advisory: false,
        //     is_archived: false,
        //     created_at: created,
        //     deleted_at: None,
        // },
        // TLE 10 - disconnected from seed
        // ClassSpec {
        //     id: cid("tle10"),
        //     title: "TLE".into(),
        //     description: Some("TLE class".into()),
        //     grade_level: Some("10".into()),
        //     school_year: Some("2025-2026".into()),
        //     is_advisory: false,
        //     is_archived: false,
        //     created_at: created,
        //     deleted_at: None,
        // },
    ]
}
