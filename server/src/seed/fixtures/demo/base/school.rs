//! Demo school settings.

use crate::seed::specs::SchoolSettingsSpec;
use crate::seed::tools::SeedContext;

pub fn demo_school_settings(ctx: &SeedContext) -> SchoolSettingsSpec {
    SchoolSettingsSpec {
        id: 1,
        school_code: "LIKHA1".into(),
        school_name: Some("Likha National High School".into()),
        school_region: Some("NCR".into()),
        school_division: Some("Division of City Schools".into()),
        school_year: Some("2025-2026".into()),
        updated_at: ctx.now(),
    }
}
