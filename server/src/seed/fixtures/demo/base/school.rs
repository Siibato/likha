//! Demo school settings.

use crate::seed::specs::SchoolDetailsSpec;
use crate::seed::tools::SeedContext;

pub fn demo_school_details(ctx: &SeedContext) -> SchoolDetailsSpec {
    SchoolDetailsSpec {
        id: 1,
        school_code: "LIKHA1".into(),
        school_name: Some("Likha National High School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        school_district: Some("District 1".into()),
        school_head_name: Some("Dr. Juan Dela Cruz".into()),
        school_head_position: Some("Principal II".into()),
        updated_at: ctx.now(),
    }
}
