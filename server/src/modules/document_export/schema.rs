use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct ExportGradeQuery {
    pub period: Option<i32>,
}
