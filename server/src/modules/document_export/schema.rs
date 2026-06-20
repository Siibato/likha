use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct ExportGradeQuery {
    pub term_number: Option<i32>,
}
