use rust_xlsxwriter::Worksheet;

use crate::utils::AppResult;

use super::layout::{field_text, Formats, FULL_WIDTH_END};
use super::excel_err;

pub fn write(
    sheet: &mut Worksheet,
    start_row: u32,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    // "REMEDIAL CLASSES" label + conducted-from line.
    sheet.set_row_height(row, 16.0).ok();
    sheet
        .merge_range(row, 0, row, 2, "REMEDIAL CLASSES", &formats.sig_label)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 3, row, 7, field_text("Conducted from (MM/DD/YYYY)", "").as_str(), &formats.field)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 8, row, 11, field_text("to (MM/DD/YYYY)", "").as_str(), &formats.field)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 12, row, 15, field_text("SCHOOL", "").as_str(), &formats.field)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 16, row, FULL_WIDTH_END, field_text("SCHOOL ID", "").as_str(), &formats.field)
        .map_err(excel_err)?;
    row += 1;

    let headers = [
        (0, 2, "Indicate if Subject is CORE, APPLIED, or SPECIALIZED"),
        (3, 15, "SUBJECTS"),
        (16, 16, "SEM FINAL GRADE"),
        (17, 17, "REMEDIAL CLASS MARK"),
        (18, 18, "RECOMPUTED FINAL GRADE"),
        (19, FULL_WIDTH_END, "ACTION TAKEN"),
    ];

    sheet.set_row_height(row, 28.0).ok();
    sheet.set_row_height(row + 1, 28.0).ok();

    for (start_col, end_col, text) in &headers {
        sheet
            .merge_range(row, *start_col, row + 1, *end_col, *text, &formats.table_header)
            .map_err(excel_err)?;
    }
    row += 2;

    for _ in 0..4 {
        for (start_col, end_col, _) in &headers {
            if start_col == end_col {
                sheet
                    .write_with_format(row, *start_col, "", &formats.table_cell_center)
                    .map_err(excel_err)?;
            } else {
                sheet
                    .merge_range(row, *start_col, row, *end_col, "", &formats.table_cell_center)
                    .map_err(excel_err)?;
            }
        }
        row += 1;
    }

    // Teacher / signature line.
    sheet.set_row_height(row, 16.0).ok();
    sheet
        .merge_range(row, 0, row, 12, field_text("Name of Teacher/Adviser", "").as_str(), &formats.field)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 13, row, FULL_WIDTH_END, field_text("Signature", "").as_str(), &formats.field)
        .map_err(excel_err)?;
    row += 1;

    Ok(row)
}
