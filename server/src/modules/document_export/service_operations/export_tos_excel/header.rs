use super::layout::*;
use crate::modules::document_export::helpers::deped_header::DepedHeaderData;

/// Writes the three centred school-identity lines (division, school name,
/// address) and returns the next free row.
pub fn write_school_header(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    total_cols: u16,
    header: &DepedHeaderData,
) -> Result<u32, rust_xlsxwriter::XlsxError> {
    let last = total_cols - 1;

    let division = if header.division.trim().is_empty() {
        " ".to_string()
    } else {
        header.division.clone()
    };
    let school_name = if header.school_name.trim().is_empty() {
        " ".to_string()
    } else {
        header.school_name.clone()
    };
    let address = if !header.district.trim().is_empty() {
        header.district.clone()
    } else if !header.region.trim().is_empty() {
        header.region.clone()
    } else {
        " ".to_string()
    };

    sheet.merge_range(start_row, 0, start_row, last, &division, &division_fmt())?;
    sheet.merge_range(start_row + 1, 0, start_row + 1, last, &school_name, &school_name_fmt())?;
    sheet.merge_range(start_row + 2, 0, start_row + 2, last, &address, &address_fmt())?;

    Ok(start_row + 3)
}

/// Writes the underlined "TABLE OF SPECIFICATION" title and returns the next
/// free row.
pub fn write_title(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    total_cols: u16,
) -> Result<u32, rust_xlsxwriter::XlsxError> {
    sheet.set_row_height(start_row, 22.0)?;
    sheet.merge_range(
        start_row,
        0,
        start_row,
        total_cols - 1,
        "TABLE OF SPECIFICATION",
        &doc_title_fmt(),
    )?;
    Ok(start_row + 1)
}

/// Writes the SUBJECT / GRADE / GRADING PERIOD / SCHOOL YEAR band across two
/// rows (labels on top, underlined values beneath) and returns the next free
/// row.
pub fn write_label_band(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    total_cols: u16,
    header: &DepedHeaderData,
) -> Result<u32, rust_xlsxwriter::XlsxError> {
    let bands = four_bands(total_cols);
    let grading_period = if header.term_label.trim().is_empty() {
        " ".to_string()
    } else {
        header.term_label.clone()
    };
    let entries = [
        ("SUBJECT", header.subject.clone()),
        ("GRADE", header.grade_level.clone()),
        ("GRADING PERIOD", grading_period),
        ("SCHOOL YEAR", header.school_year.clone()),
    ];

    let value_row = start_row + 1;
    for (i, (label, value)) in entries.iter().enumerate() {
        let (s, e) = bands[i];
        let v = if value.trim().is_empty() { " ".to_string() } else { value.clone() };
        if e > s {
            sheet.merge_range(start_row, s, start_row, e, *label, &band_label_fmt())?;
            sheet.merge_range(value_row, s, value_row, e, &v, &band_value_fmt())?;
        } else {
            sheet.write_with_format(start_row, s, *label, &band_label_fmt())?;
            sheet.write_with_format(value_row, s, &v, &band_value_fmt())?;
        }
    }
    Ok(value_row + 1)
}

/// Writes the LEGEND line and the "Prepared by" signature block beneath the
/// table. Returns the next free row.
pub fn write_legend_and_footer(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    total_cols: u16,
    teacher_name: &str,
) -> Result<u32, rust_xlsxwriter::XlsxError> {
    let last = total_cols - 1;

    // LEGEND row, directly under the table.
    sheet.merge_range(
        start_row,
        0,
        start_row,
        last,
        "LEGEND:   NOI - Number of Items        POI - Placement of Items",
        &legend_fmt(),
    )?;

    // Signature block, right-aligned (last ~3 columns).
    let sig_row = start_row + 3;
    let sig_start = total_cols.saturating_sub(3);
    let line_start = sig_start + 1;

    sheet.write_with_format(sig_row, sig_start, "Prepared by:", &footer_label_fmt())?;
    let name = if teacher_name.trim().is_empty() { " ".to_string() } else { teacher_name.to_string() };
    if last > line_start {
        sheet.merge_range(sig_row, line_start, sig_row, last, &name, &footer_line_fmt())?;
        sheet.merge_range(sig_row + 1, line_start, sig_row + 1, last, "Subject Teacher", &footer_caption_fmt())?;
    } else {
        sheet.write_with_format(sig_row, line_start, &name, &footer_line_fmt())?;
        sheet.write_with_format(sig_row + 1, line_start, "Subject Teacher", &footer_caption_fmt())?;
    }

    Ok(sig_row + 2)
}
