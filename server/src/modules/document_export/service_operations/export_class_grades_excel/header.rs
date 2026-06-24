use super::layout::*;
use crate::modules::document_export::helpers::deped_header::DepedHeaderData;
use crate::modules::document_export::helpers::excel_engine::{label_fmt, underline_fmt};

// ─────────────────────────────────────────────────────────────────────────────
// Header grid  (rows 2 & 3)
// ─────────────────────────────────────────────────────────────────────────────

pub fn write_header_grid(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    total_cols: u16,
    header: &DepedHeaderData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let blank = rust_xlsxwriter::Format::new().set_border(rust_xlsxwriter::FormatBorder::Thin);

    // col 0 is the name column — leave blank both rows
    sheet.write_with_format(start_row, 0, "", &blank)?;
    sheet.write_with_format(start_row + 1, 0, "", &blank)?;

    // Distribute remaining cols into 3 equal-ish bands
    let remaining = (total_cols - 1) as usize;
    let base_band = remaining / 3;
    let extra = remaining % 3;
    let band_widths: Vec<usize> = (0..3)
        .map(|i| base_band + if i < extra { 1 } else { 0 })
        .collect();

    let row_a = [
        ("REGION", header.region.as_str()),
        ("DIVISION", header.division.as_str()),
        ("DISTRICT", header.district.as_str()),
    ];
    let row_b = [
        ("SCHOOL NAME", header.school_name.as_str()),
        ("SCHOOL ID", header.school_id.as_str()),
        ("SCHOOL YEAR", header.school_year.as_str()),
    ];

    for (row_offset, fields) in [(0u32, &row_a), (1u32, &row_b)] {
        let row = start_row + row_offset;
        let mut col = 1u16;

        for (i, (lbl, val)) in fields.iter().enumerate() {
            let band = band_widths[i];
            let label_col = col;
            let val_start = col + 1;
            let val_end = col + band as u16 - 1;

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
// Class info row
// ─────────────────────────────────────────────────────────────────────────────

pub fn write_class_info_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    total_cols: u16,
    header: &DepedHeaderData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let uline = underline_fmt();
    let lbl = label_fmt();

    let grey_fmt = rust_xlsxwriter::Format::new()
        .set_bold()
        .set_font_size(9)
        .set_align(rust_xlsxwriter::FormatAlign::Center)
        .set_align(rust_xlsxwriter::FormatAlign::VerticalCenter)
        .set_background_color(rust_xlsxwriter::Color::RGB(0xD9D9D9))
        .set_border(rust_xlsxwriter::FormatBorder::Thin);

    // col 0: term label
    sheet.write_with_format(row, 0, &header.term_label, &lbl)?;

    // col 1: "GRADE & SECTION:"
    sheet.write_with_format(row, 1, "GRADE & SECTION:", &lbl)?;

    // col 2–5: grade+section value
    let gs = format!("{} {}", header.grade_level, header.section)
        .trim()
        .to_string();
    let gs = if gs.is_empty() { " ".to_string() } else { gs };
    sheet.merge_range(row, 2, row, 5, &gs, &uline)?;

    // col 6: "TEACHER:"
    sheet.write_with_format(row, 6, "TEACHER:", &lbl)?;

    // col 7–10: teacher name
    let t = if header.teacher_name.is_empty() {
        " ".to_string()
    } else {
        header.teacher_name.clone()
    };
    sheet.merge_range(row, 7, row, 10, &t, &uline)?;

    // col 11: "SUBJECT:"
    sheet.write_with_format(row, 11, "SUBJECT:", &lbl)?;

    // Reserve last 2 cols for grey badge
    let badge_start = total_cols.saturating_sub(2);
    let subj_end = badge_start.saturating_sub(1);

    if subj_end > 12 {
        let s = if header.subject.is_empty() {
            " "
        } else {
            header.subject.as_str()
        };
        sheet.merge_range(row, 12, row, subj_end, s, &uline)?;
    } else {
        let s = if header.subject.is_empty() {
            " "
        } else {
            header.subject.as_str()
        };
        sheet.write_with_format(row, 12, s, &uline)?;
    }

    // Grey badge: last 2 cols
    if badge_start + 1 < total_cols {
        sheet.merge_range(
            row,
            badge_start,
            row,
            total_cols - 1,
            &header.term_label,
            &grey_fmt,
        )?;
    } else {
        sheet.write_with_format(row, badge_start, &header.term_label, &grey_fmt)?;
    }

    Ok(())
}
