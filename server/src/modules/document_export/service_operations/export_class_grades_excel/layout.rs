use rust_xlsxwriter::{Color, Format, FormatAlign, FormatBorder};

use crate::modules::document_export::helpers::grade_table::GradeTableData;

// ─────────────────────────────────────────────────────────────────────────────
// Shared format helpers
// ─────────────────────────────────────────────────────────────────────────────

/// White-background, centered, bold, thin-bordered — used for ALL header cells.
pub fn tbl_header_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_text_wrap()
}

pub fn val_fmt() -> Format {
    Format::new()
        .set_font_size(9)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
}

pub fn grey_cell_fmt() -> Format {
    Format::new()
        .set_background_color(Color::RGB(0xD9D9D9))
        .set_border(FormatBorder::Thin)
}

pub fn remarks_pass_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_bold()
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_font_color(Color::RGB(0x375623))
        .set_border(FormatBorder::Thin)
}

pub fn remarks_fail_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_bold()
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_font_color(Color::RGB(0xC00000))
        .set_border(FormatBorder::Thin)
}

// ─────────────────────────────────────────────────────────────────────────────
// Column widths  (+1 for REMARKS)
// ─────────────────────────────────────────────────────────────────────────────

pub fn set_column_widths(sheet: &mut rust_xlsxwriter::Worksheet, table: &GradeTableData) {
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
// Column index helper  — REMARKS col is always last (tg_col + 1)
// ─────────────────────────────────────────────────────────────────────────────

pub fn calc_col_indices(table: &GradeTableData) -> (i32, i32, i32, i32, i32, i32, i32) {
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
