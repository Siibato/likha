use std::sync::Arc;

use rust_xlsxwriter::Image;
use uuid::Uuid;

use crate::modules::document_export::helpers::deped_header::DepedHeaderData;
use crate::modules::document_export::helpers::excel_engine::{
    subtitle_fmt, title_fmt, ExcelEngine,
};
use crate::modules::document_export::helpers::grade_table::GradeTableData;
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::utils::{AppError, AppResult};

pub mod header;
pub mod layout;
pub mod table;

// Re-export layout items so submodules can use `super::*`
pub use layout::*;

impl DocumentExportService {
    pub async fn export_class_grades_excel(
        &self,
        class_id: Uuid,
        term_number: i32,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(
            &self.grade_service,
            &self.setup_service,
            class_id,
            term_number,
            teacher_id,
        )
        .await
    }
}

pub async fn run(
    grade_service: &Arc<GradeComputationService>,
    setup_service: &Arc<SetupService>,
    class_id: Uuid,
    term_number: i32,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    if !grade_service
        .class_repo
        .is_teacher_of_class(teacher_id, class_id)
        .await?
    {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let grade_data = grade_service
        .get_all_grade_data(class_id, term_number)
        .await?;
    let settings = setup_service.get_school_details().await?;
    let class_model = grade_service
        .class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;
    let teacher = grade_service
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
        term_number,
    );

    let table = GradeTableData::build(&grade_data);

    let mut engine = ExcelEngine::new();
    let sheet = engine.worksheet();

    layout::set_column_widths(sheet, &table);

    // total_cols now includes the extra REMARKS column
    let total_cols = table.total_columns() as u16 + 1; // +1 for REMARKS
    let mut row: u32 = 0;

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
        let img = img.set_scale_to_size(110, 60, true);
        sheet
            .insert_image_with_offset(0, total_cols.saturating_sub(1), &img, 0, 2)
            .map_err(|e| AppError::InternalServerError(format!("Excel image: {}", e)))?;
    }

    // ── Row 0: title ─────────────────────────────────────────────────────────
    sheet
        .merge_range(row, 0, row, total_cols - 1, "Class Record", &title_fmt())
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    // ── Row 1: subtitle ──────────────────────────────────────────────────────
    sheet
        .merge_range(
            row,
            0,
            row,
            total_cols - 1,
            "(Pursuant to DepEd Order 8 series of 2015)",
            &subtitle_fmt(),
        )
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    // ── Rows 2-3: REGION/DIVISION/DISTRICT + SCHOOL NAME/ID/YEAR ─────────────
    header::write_header_grid(sheet, row, total_cols, &header)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 2;

    // ── Row 4: class info ────────────────────────────────────────────────────
    header::write_class_info_row(sheet, row, total_cols, &header)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    // ── Grade table ──────────────────────────────────────────────────────────
    table::write_section_header_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    table::write_column_header_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    table::write_hps_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    table::write_student_rows(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("Excel save: {}", e)))
}
