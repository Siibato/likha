use std::sync::Arc;

use rust_xlsxwriter::{Format, FormatAlign, FormatBorder, Color, Image};
use uuid::Uuid;

use crate::modules::document_export::helpers::deped_header::DepedHeaderData;
use crate::modules::document_export::helpers::excel_engine::{
    ExcelEngine, bordered_data_fmt, label_fmt, subtitle_fmt, title_fmt, underline_fmt,
};
use crate::modules::document_export::helpers::grade_table::GradeTableData;
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::utils::{AppError, AppResult};

impl DocumentExportService {
    pub async fn export_class_grades_excel(
        &self,
        class_id: Uuid,
        period: i32,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(
            &self.grade_service,
            &self.setup_service,
            class_id,
            period,
            teacher_id,
        )
        .await
    }
}

pub async fn run(
    grade_service: &Arc<GradeComputationService>,
    setup_service: &Arc<SetupService>,
    class_id: Uuid,
    period: i32,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    if !grade_service
        .class_repo
        .is_teacher_of_class(teacher_id, class_id)
        .await?
    {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let grade_data = grade_service.get_all_grade_data(class_id, period).await?;
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
    let teacher_name = teacher.map(|t| t.full_name).unwrap_or_default();

    let header = DepedHeaderData::from_settings(
        &settings,
        &class_model.title,
        class_model.grade_level.as_deref(),
        &teacher_name,
        period,
    );

    let table = GradeTableData::build(&grade_data);

    let mut engine = ExcelEngine::new();
    let sheet = engine.worksheet();

    set_column_widths(sheet, &table);

    // total_cols now includes the extra REMARKS column
    let total_cols = table.total_columns() as u16 + 1; // +1 for REMARKS
    let mut row: u32 = 0;

    // ── Logos ────────────────────────────────────────────────────────────────
    let seal_path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("assets/images/deped_seal.png");
    let logo_path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("assets/images/deped_logo.png");

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
            row, 0, row, total_cols - 1,
            "(Pursuant to DepEd Order 8 series of 2015)",
            &subtitle_fmt(),
        )
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    // ── Rows 2-3: REGION/DIVISION/DISTRICT + SCHOOL NAME/ID/YEAR ─────────────
    write_header_grid(sheet, row, total_cols, &header)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 2;

    // ── Row 4: class info ────────────────────────────────────────────────────
    write_class_info_row(sheet, row, total_cols, &header)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    // ── Grade table ──────────────────────────────────────────────────────────
    write_section_header_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    write_column_header_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    write_hps_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    write_gender_row(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    row += 1;

    write_student_rows(sheet, row, &table)
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("Excel save: {}", e)))
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared format helpers
// ─────────────────────────────────────────────────────────────────────────────

/// White-background, centered, bold, thin-bordered — used for ALL header cells.
/// No blue, no yellow.
fn tbl_header_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_text_wrap()
}

fn val_fmt() -> Format {
    Format::new()
        .set_font_size(9)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
}

fn grey_cell_fmt() -> Format {
    Format::new()
        .set_background_color(Color::RGB(0xD9D9D9))
        .set_border(FormatBorder::Thin)
}

fn remarks_pass_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_bold()
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_font_color(Color::RGB(0x375623)) // dark green
        .set_border(FormatBorder::Thin)
}

fn remarks_fail_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_bold()
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_font_color(Color::RGB(0xC00000)) // dark red
        .set_border(FormatBorder::Thin)
}

// ─────────────────────────────────────────────────────────────────────────────
// Column widths  (+1 for REMARKS)
// ─────────────────────────────────────────────────────────────────────────────

fn set_column_widths(sheet: &mut rust_xlsxwriter::Worksheet, table: &GradeTableData) {
    let mut col = 0u16;

    sheet.set_column_width(col, 24.0).unwrap(); // learner name
    col += 1;

    for section in [&table.ww, &table.pt, &table.qa] {
        if section.items.is_empty() { continue; }
        for _ in &section.items {
            sheet.set_column_width(col, 4.0).unwrap();
            col += 1;
        }
        sheet.set_column_width(col, 5.5).unwrap(); col += 1; // Total
        sheet.set_column_width(col, 6.5).unwrap(); col += 1; // PS
        sheet.set_column_width(col, 6.5).unwrap(); col += 1; // WS
    }

    sheet.set_column_width(col, 7.5).unwrap(); col += 1; // Initial Grade
    sheet.set_column_width(col, 8.0).unwrap(); col += 1; // Term Grade
    sheet.set_column_width(col, 7.0).unwrap();           // Remarks
}

// ─────────────────────────────────────────────────────────────────────────────
// Header grid  (rows 2 & 3)
//
//  col 0 blank  │ REGION label │ value ───── │ DIVISION label │ value ─── │ DISTRICT label │ value ───
//  col 0 blank  │ SCHOOL NAME  │ value ───── │ SCHOOL ID      │ value ─── │ SCHOOL YEAR    │ value ───
// ─────────────────────────────────────────────────────────────────────────────

fn write_header_grid(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    total_cols: u16,
    header: &DepedHeaderData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let blank = Format::new().set_border(FormatBorder::Thin);

    // col 0 is the name column — leave blank both rows
    sheet.write_with_format(start_row,     0, "", &blank)?;
    sheet.write_with_format(start_row + 1, 0, "", &blank)?;

    // Distribute remaining cols into 3 equal-ish bands
    let remaining  = (total_cols - 1) as usize;
    let base_band  = remaining / 3;
    let extra      = remaining % 3;
    let band_widths: Vec<usize> = (0..3)
        .map(|i| base_band + if i < extra { 1 } else { 0 })
        .collect();

    let row_a = [
        ("REGION",   header.region.as_str()),
        ("DIVISION", header.division.as_str()),
        ("DISTRICT", header.district.as_str()),
    ];
    let row_b = [
        ("SCHOOL NAME", header.school_name.as_str()),
        ("SCHOOL ID",   header.school_id.as_str()),
        ("SCHOOL YEAR", header.school_year.as_str()),
    ];

    for (row_offset, fields) in [(0u32, &row_a), (1u32, &row_b)] {
        let row = start_row + row_offset;
        let mut col = 1u16;

        for (i, (lbl, val)) in fields.iter().enumerate() {
            let band      = band_widths[i];
            let label_col = col;
            let val_start = col + 1;
            let val_end   = col + band as u16 - 1;

            sheet.write_with_format(row, label_col, *lbl, &label_fmt())?;

            let v = if val.is_empty() { " " } else { val };
            if val_end > val_start {
                sheet.merge_range(row, val_start, row, val_end, v, &val_fmt())?;
            } else {
                sheet.write_with_format(row, val_start, v, &val_fmt())?;
            }

            col += band as u16;
        }
    }

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Class info row  (Term label | GRADE & SECTION | TEACHER | SUBJECT)
// FIX: no "QUARTER 1" label on left; use header.quarter_label only for the
//      right-side grey badge.  Grade & Section now gets 4 cols so it never clips.
// ─────────────────────────────────────────────────────────────────────────────

fn write_class_info_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    total_cols: u16,
    header: &DepedHeaderData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let uline = underline_fmt();
    let lbl   = label_fmt();

    let grey_fmt = Format::new()
        .set_bold()
        .set_font_size(9)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_background_color(Color::RGB(0xD9D9D9))
        .set_border(FormatBorder::Thin);

    // col 0: term label (e.g. "TERM 1") — matches Image 2 left cell
    sheet.write_with_format(row, 0, &header.quarter_label, &lbl)?;

    // col 1: "GRADE & SECTION:"
    sheet.write_with_format(row, 1, "GRADE & SECTION:", &lbl)?;

    // col 2–5: grade+section value — 4 cols so long names don't clip
    let gs = format!("{} {}", header.grade_level, header.section)
        .trim()
        .to_string();
    let gs = if gs.is_empty() { " ".to_string() } else { gs };
    sheet.merge_range(row, 2, row, 5, &gs, &uline)?;

    // col 6: "TEACHER:"
    sheet.write_with_format(row, 6, "TEACHER:", &lbl)?;

    // col 7–10: teacher name — 4 cols
    let t = if header.teacher_name.is_empty() { " ".to_string() } else { header.teacher_name.clone() };
    sheet.merge_range(row, 7, row, 10, &t, &uline)?;

    // col 11: "SUBJECT:"
    sheet.write_with_format(row, 11, "SUBJECT:", &lbl)?;

    // col 12 .. (badge_start - 1): subject value
    // Reserve last 2 cols for grey badge
    let badge_start = total_cols.saturating_sub(2);
    let subj_end    = badge_start.saturating_sub(1);

    if subj_end > 12 {
        let s = if header.subject.is_empty() { " " } else { header.subject.as_str() };
        sheet.merge_range(row, 12, row, subj_end, s, &uline)?;
    } else {
        let s = if header.subject.is_empty() { " " } else { header.subject.as_str() };
        sheet.write_with_format(row, 12, s, &uline)?;
    }

    // Grey badge: last 2 cols
    if badge_start + 1 < total_cols {
        sheet.merge_range(row, badge_start, row, total_cols - 1,
            &header.quarter_label, &grey_fmt)?;
    } else {
        sheet.write_with_format(row, badge_start, &header.quarter_label, &grey_fmt)?;
    }

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Column index helper  — REMARKS col is always last (qg_col + 1)
// ─────────────────────────────────────────────────────────────────────────────

fn calc_col_indices(table: &GradeTableData) -> (i32, i32, i32, i32, i32, i32, i32) {
    let ww_cols = if !table.ww.items.is_empty() { table.ww.items.len() + 3 } else { 0 };
    let pt_cols = if !table.pt.items.is_empty() { table.pt.items.len() + 3 } else { 0 };
    let qa_cols = if !table.qa.items.is_empty() { table.qa.items.len() + 3 } else { 0 };

    let mut col: i32 = 0;
    let name_col    = col; col += 1;
    let ww_start    = if ww_cols > 0 { col } else { -1 }; col += ww_cols as i32;
    let pt_start    = if pt_cols > 0 { col } else { -1 }; col += pt_cols as i32;
    let qa_start    = if qa_cols > 0 { col } else { -1 }; col += qa_cols as i32;
    let initial_col = col; col += 1;
    let tg_col      = col; col += 1;
    let remarks_col = col;

    (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col)
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header row
// ─────────────────────────────────────────────────────────────────────────────

fn write_section_header_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "LEARNERS' NAMES", &fmt)?;

    for (section, start, prefix) in [
        (&table.ww, ww_start, "WRITTEN WORKS"),
        (&table.pt, pt_start, "PERFORMANCE TASKS"),
        (&table.qa, qa_start, "QUARTERLY ASSESSMENT"),
    ] {
        if start < 0 { continue; }
        let span  = (section.items.len() + 3) as i32;
        let label = format!("{}({:.0}%)", prefix, section.weight);
        sheet.merge_range(row, start as u16, row, (start + span - 1) as u16, &label, &fmt)?;
    }

    sheet.write_with_format(row, initial_col  as u16, "INITIAL\nGRADE",   &fmt)?;
    // ── FIX: "TERM GRADE" not "QUARTERLY GRADE" ──
    sheet.write_with_format(row, tg_col       as u16, "TERM\nGRADE",      &fmt)?;
    sheet.write_with_format(row, remarks_col  as u16, "REMARKS",           &fmt)?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Column sub-header row
// ─────────────────────────────────────────────────────────────────────────────

fn write_column_header_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "", &fmt)?;

    for (section, start) in [(&table.ww, ww_start), (&table.pt, pt_start), (&table.qa, qa_start)] {
        if start < 0 { continue; }
        for (i, _) in section.items.iter().enumerate() {
            sheet.write_with_format(row, (start + i as i32) as u16, (i + 1).to_string(), &fmt)?;
        }
        let n = section.items.len() as i32;
        sheet.write_with_format(row, (start + n)     as u16, "Total", &fmt)?;
        sheet.write_with_format(row, (start + n + 1) as u16, "PS",    &fmt)?;
        sheet.write_with_format(row, (start + n + 2) as u16, "WS",    &fmt)?;
    }

    sheet.write_with_format(row, initial_col as u16, "Grade", &fmt)?;
    sheet.write_with_format(row, tg_col      as u16, "Grade", &fmt)?;
    sheet.write_with_format(row, remarks_col as u16, "",      &fmt)?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// HPS row
// ─────────────────────────────────────────────────────────────────────────────

fn write_hps_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "HIGHEST POSSIBLE SCORE", &fmt)?;

    for (section, start) in [(&table.ww, ww_start), (&table.pt, pt_start), (&table.qa, qa_start)] {
        if start < 0 { continue; }
        for (i, item) in section.items.iter().enumerate() {
            sheet.write_with_format(row, (start + i as i32) as u16,
                format!("{:.0}", item.total_points), &fmt)?;
        }
        let n = section.items.len() as i32;
        sheet.write_with_format(row, (start + n)     as u16, format!("{:.0}", section.hps_total), &fmt)?;
        sheet.write_with_format(row, (start + n + 1) as u16, "100.00", &fmt)?;
        sheet.write_with_format(row, (start + n + 2) as u16, format!("{:.0}%", section.weight), &fmt)?;
    }

    sheet.write_with_format(row, initial_col as u16, "", &grey_cell_fmt())?;
    sheet.write_with_format(row, tg_col      as u16, "", &grey_cell_fmt())?;
    sheet.write_with_format(row, remarks_col as u16, "", &grey_cell_fmt())?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// MALE gender row
// ─────────────────────────────────────────────────────────────────────────────

fn write_gender_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "MALE", &fmt)?;

    for (section, start) in [(&table.ww, ww_start), (&table.pt, pt_start), (&table.qa, qa_start)] {
        if start < 0 { continue; }
        for c in 0..(section.items.len() as i32 + 3) {
            sheet.write_with_format(row, (start + c) as u16, "", &fmt)?;
        }
    }

    sheet.write_with_format(row, initial_col as u16, "", &fmt)?;
    sheet.write_with_format(row, tg_col      as u16, "", &fmt)?;
    sheet.write_with_format(row, remarks_col as u16, "", &fmt)?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Student rows  — with REMARKS
// ─────────────────────────────────────────────────────────────────────────────

fn write_student_rows(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let data_fmt = bordered_data_fmt();

    let mut row = start_row;
    for sr in &table.students {
        // Name
        let name = format!("{}. {}", sr.index, sr.student_name);
        sheet.write_with_format(row, name_col as u16, &name, &data_fmt)?;

        // Scores
        for (result, section, start) in [
            (&sr.ww, &table.ww, ww_start),
            (&sr.pt, &table.pt, pt_start),
            (&sr.qa, &table.qa, qa_start),
        ] {
            if start < 0 { continue; }
            for (i, score) in result.scores.iter().enumerate() {
                let text = score.map(|s| format!("{:.1}", s)).unwrap_or_default();
                sheet.write_with_format(row, (start + i as i32) as u16, &text, &data_fmt)?;
            }
            let n = section.items.len() as i32;
            sheet.write_with_format(row, (start + n)     as u16,
                result.total.map(|t| format!("{:.1}", t)).unwrap_or_default(), &data_fmt)?;
            sheet.write_with_format(row, (start + n + 1) as u16,
                result.ps.map(|p| format!("{:.2}", p)).unwrap_or_default(), &data_fmt)?;
            sheet.write_with_format(row, (start + n + 2) as u16,
                result.ws.map(|w| format!("{:.2}", w)).unwrap_or_default(), &data_fmt)?;
        }

        // Initial grade
        sheet.write_with_format(
            row, initial_col as u16,
            sr.initial_grade.map(|v| format!("{:.2}", v)).unwrap_or_default(),
            &data_fmt,
        )?;

        // Term grade
        sheet.write_with_format(
            row, tg_col as u16,
            sr.transmuted_grade.map(|v| v.to_string()).unwrap_or_default(),
            &data_fmt,
        )?;

        // ── REMARKS: Pass / Fail ─────────────────────────────────────────────
        let (remarks_text, remarks_fmt) = match sr.transmuted_grade {
            Some(tg) if tg >= 75 => ("PASSED", remarks_pass_fmt()),
            Some(_)              => ("FAILED", remarks_fail_fmt()),
            None                 => ("",       bordered_data_fmt()),
        };
        sheet.write_with_format(row, remarks_col as u16, remarks_text, &remarks_fmt)?;

        row += 1;
    }
    Ok(())
}