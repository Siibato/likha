use crate::modules::setup::schema::SchoolDetailsResponse;

pub struct DepedHeaderData {
    pub region: String,
    pub division: String,
    pub district: String,
    pub school_name: String,
    pub school_id: String,
    pub school_year: String,
    pub grade_level: String,
    pub section: String,
    pub teacher_name: String,
    pub subject: String,
    pub term_label: String,
}

impl DepedHeaderData {
    pub fn from_settings(
        settings: &SchoolDetailsResponse,
        class_title: &str,
        grade_level: Option<&str>,
        teacher_name: &str,
        term_number: i32,
    ) -> Self {
        Self {
            region: settings.school_region.clone().unwrap_or_default(),
            division: settings.school_division.clone().unwrap_or_default(),
            district: settings.school_district.clone().unwrap_or_default(),
            school_name: settings.school_name.clone().unwrap_or_default(),
            school_id: settings.school_code.clone(),
            school_year: settings.school_year.clone().unwrap_or_default(),
            grade_level: grade_level.unwrap_or("").to_string(),
            section: class_title.to_string(),
            teacher_name: teacher_name.to_string(),
            subject: class_title.to_string(),
            term_label: format!("TERM {}", term_number),
        }
    }
}
