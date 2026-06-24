use std::sync::Arc;

use chrono::NaiveDate;
use uuid::Uuid;

use crate::modules::document_export::helpers::excel_engine::ExcelEngine;
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::helpers::deped_weights;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::schema::SchoolDetailsResponse;
use crate::modules::setup::service::SetupService;
use crate::modules::student_records::schema::{Sf10Response, Sf10SubjectRow, Sf10YearRecord};
use crate::modules::student_records::service::StudentRecordsService;
use crate::utils::{AppError, AppResult};

mod eligibility;
mod header;
mod layout;
mod learner_info;
mod remedial;
mod remarks;
mod scholastic;

use layout::{apply_column_widths, Formats, SEMESTERS};

pub(crate) struct Sf10ExcelContext<'a> {
    pub sf10: &'a Sf10Response,
    pub settings: &'a SchoolDetailsResponse,
    pub adviser_name: &'a str,
}

impl DocumentExportService {
    pub async fn export_sf10_excel(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(
            &self.grade_service,
            &self.student_records_service,
            &self.setup_service,
            class_id,
            student_id,
            teacher_id,
        )
        .await
    }
}

pub async fn run(
    grade_service: &Arc<GradeComputationService>,
    student_records_service: &Arc<StudentRecordsService>,
    setup_service: &Arc<SetupService>,
    class_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    let sf10 = student_records_service
        .get_sf10(class_id, student_id, teacher_id)
        .await?;
    let settings = setup_service.get_school_details().await?;

    let adviser_name_owned = grade_service
        .class_repo
        .find_teacher_of_class(class_id)
        .await?
        .map(|t| format!("{}, {}", t.last_name, t.first_name))
        .unwrap_or_default();

    let mut engine = ExcelEngine::new();
    let sheet = engine.worksheet();
    sheet.set_name("SF10").ok();
    apply_column_widths(sheet);

    let ctx = Sf10ExcelContext {
        sf10: &sf10,
        settings: &settings,
        adviser_name: adviser_name_owned.as_str(),
    };

    let formats = Formats::new();
    let mut row: u32 = 0;

    row = header::write(sheet, row, &ctx, &formats)?;
    row = learner_info::write(sheet, row + 1, &ctx, &formats)?;
    row = eligibility::write(sheet, row + 1, &ctx, &formats)?;

    for record in &sf10.scholastic_records {
        for sem in SEMESTERS.iter() {
            row = scholastic::write_semester_block(sheet, row + 1, &ctx, record, sem, &formats)?;
            row = remarks::write_signature_block(sheet, row + 1, &ctx, record, &formats)?;
            row = remedial::write(sheet, row + 1, &formats)?;
        }
    }

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("Excel save: {}", e)))
}

pub(crate) fn excel_err(e: impl std::fmt::Display) -> AppError {
    AppError::InternalServerError(format!("Excel: {}", e))
}

pub(crate) struct NameParts {
    pub last: String,
    pub first: String,
    pub middle: String,
}

pub(crate) fn split_name(full: &str) -> NameParts {
    let mut last = String::new();
    let mut first = String::new();
    let mut middle = String::new();

    if let Some((l, rest)) = full.split_once(',') {
        last = l.trim().to_string();
        let rest = rest.trim();
        if let Some((f, m)) = rest.split_once(' ') {
            first = f.trim().to_string();
            middle = m.trim().to_string();
        } else {
            first = rest.to_string();
        }
    } else {
        first = full.trim().to_string();
    }

    NameParts { last, first, middle }
}

pub(crate) fn format_date(raw: Option<&String>) -> String {
    raw.and_then(|value| NaiveDate::parse_from_str(value, "%Y-%m-%d").ok())
        .map(|d| d.format("%m/%d/%Y").to_string())
        .unwrap_or_default()
}

pub(crate) fn format_optional(value: Option<&String>) -> String {
    value.map(|v| v.to_string()).unwrap_or_default()
}

pub(crate) fn grade_for_indices(subject: &Sf10SubjectRow, indices: &[usize]) -> Option<i32> {
    let mut grades = Vec::new();
    for idx in indices {
        if let Some(entry) = subject.term_grades.get(*idx).and_then(|g| *g) {
            grades.push(entry);
        }
    }
    if grades.is_empty() {
        None
    } else {
        let avg = grades.iter().sum::<i32>() as f64 / grades.len() as f64;
        Some(avg.round() as i32)
    }
}

pub(crate) fn action_taken(grade: Option<i32>) -> Option<&'static str> {
    grade.map(|g| if g >= 75 { "PASSED" } else { "FAILED" })
}

pub(crate) fn descriptor_for_grade(grade: Option<i32>) -> Option<String> {
    grade.map(|g| deped_weights::get_descriptor(g).to_string())
}

pub(crate) fn resolve_school_name<'a>(record: &'a Sf10YearRecord, ctx: &'a Sf10ExcelContext<'_>) -> String {
    if record.school_name.trim().is_empty() {
        ctx.settings
            .school_name
            .clone()
            .unwrap_or_else(|| "".to_string())
    } else {
        record.school_name.clone()
    }
}
