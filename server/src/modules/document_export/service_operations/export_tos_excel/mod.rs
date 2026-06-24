use std::sync::Arc;

use rust_xlsxwriter::Image;
use uuid::Uuid;

use crate::modules::document_export::helpers::deped_header::DepedHeaderData;
use crate::modules::document_export::helpers::excel_engine::ExcelEngine;
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::setup::service::SetupService;
use crate::modules::tos::service::TosService;
use crate::utils::{AppError, AppResult};

pub mod header;
pub mod layout;
pub mod table;

pub use layout::*;

impl DocumentExportService {
    pub async fn export_tos_excel(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(&self.tos_service, &self.setup_service, tos_id, teacher_id).await
    }
}

pub async fn run(
    tos_service: &Arc<TosService>,
    setup_service: &Arc<SetupService>,
    tos_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    let tos = tos_service
        .get_tos_for_teacher(tos_id, teacher_id)
        .await?;
    let settings = setup_service.get_school_details().await?;

    let class_id = Uuid::parse_str(&tos.class_id)
        .map_err(|_| AppError::InternalServerError("Invalid TOS class id".to_string()))?;

    let class_model = tos_service
        .class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    let teacher = tos_service
        .class_repo
        .find_teacher_of_class(class_id)
        .await?;

    let teacher_name = teacher
        .map(|t| format!("{}, {}", t.last_name, t.first_name))
        .unwrap_or_default();

    let header = DepedHeaderData::from_settings(
        &settings,
        &class_model.title,
        class_model.grade_level.as_deref(),
        &teacher_name,
        tos.term_number,
    );

    let mut engine = ExcelEngine::new();
    let sheet = engine.worksheet();
    sheet.set_name("TOS").ok();

    let is_blooms = tos.classification_mode == "blooms";
    let total_cols = layout::total_columns(is_blooms);

    layout::set_column_widths(sheet, is_blooms);

    // ── Logos ────────────────────────────────────────────────────────────────
    let seal_path =
        std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("assets/images/deped_seal.png");
    let logo_path =
        std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("assets/images/deped_logo.png");

    if let Ok(img) = Image::new(&seal_path) {
        let img = img.set_scale_to_size(80, 80, true);
        sheet
            .insert_image(0, 0, &img)
            .map_err(|e| AppError::InternalServerError(format!("Excel image: {}", e)))?;
    }
    if let Ok(img) = Image::new(&logo_path) {
        let img = img.set_scale_to_size(80, 80, true);
        sheet
            .insert_image(0, total_cols.saturating_sub(1), &img)
            .map_err(|e| AppError::InternalServerError(format!("Excel image: {}", e)))?;
    }

    let mut row: u32 = 0;

    // ── Division / School name / Address ─────────────────────────────────────
    row = header::write_school_header(sheet, row, total_cols, &header)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1; // spacer

    // ── Title: TABLE OF SPECIFICATION ────────────────────────────────────────
    row = header::write_title(sheet, row, total_cols)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1; // spacer

    // ── SUBJECT / GRADE / GRADING PERIOD / SCHOOL YEAR band ──────────────────
    row = header::write_label_band(sheet, row, total_cols, &header)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1; // spacer

    // ── Specification table ──────────────────────────────────────────────────
    let after_table = table::write_table(sheet, row, &tos)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;

    header::write_legend_and_footer(sheet, after_table, total_cols, &header.teacher_name)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("Excel save: {}", e)))
}
