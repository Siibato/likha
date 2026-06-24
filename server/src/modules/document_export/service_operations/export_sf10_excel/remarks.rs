use rust_xlsxwriter::Worksheet;

use crate::modules::student_records::schema::Sf10YearRecord;
use crate::utils::AppResult;

use super::layout::{field_text, Formats, FULL_WIDTH_END};
use super::{action_taken, excel_err, Sf10ExcelContext};

pub fn write_signature_block(
    sheet: &mut Worksheet,
    start_row: u32,
    ctx: &Sf10ExcelContext<'_>,
    record: &Sf10YearRecord,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    // REMARKS line.
    let descriptor = record
        .descriptor
        .clone()
        .filter(|d| !d.is_empty())
        .or_else(|| action_taken(record.final_average).map(|s| s.to_string()))
        .unwrap_or_else(|| "PROMOTED".to_string());
    sheet
        .merge_range(
            row,
            0,
            row,
            FULL_WIDTH_END,
            field_text("REMARKS", &descriptor).as_str(),
            &formats.field,
        )
        .map_err(excel_err)?;
    row += 1;

    // Signature column labels.
    sheet
        .merge_range(row, 0, row, 6, "Prepared by:", &formats.sig_label)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 7, row, 14, "Certified True and Correct:", &formats.sig_label)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 15, row, FULL_WIDTH_END, "Date Checked (MM/DD/YYYY):", &formats.sig_label)
        .map_err(excel_err)?;
    row += 1;

    // Blank space for the actual signatures.
    sheet.set_row_height(row, 26.0).ok();
    row += 1;

    // Printed names (underlined).
    sheet
        .merge_range(row, 0, row, 6, ctx.adviser_name, &formats.sig_name)
        .map_err(excel_err)?;

    let principal = ctx.settings.school_head_name.clone().unwrap_or_default();
    let principal_title = ctx
        .settings
        .school_head_position
        .clone()
        .unwrap_or_default();
    let authorized = if principal_title.trim().is_empty() {
        principal
    } else if principal.trim().is_empty() {
        principal_title
    } else {
        format!("{}, {}", principal, principal_title)
    };
    sheet
        .merge_range(row, 7, row, 14, authorized.as_str(), &formats.sig_name)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 15, row, FULL_WIDTH_END, "", &formats.sig_name)
        .map_err(excel_err)?;
    row += 1;

    // Captions.
    sheet
        .merge_range(row, 0, row, 6, "Signature of Adviser over Printed Name", &formats.sig_caption)
        .map_err(excel_err)?;
    sheet
        .merge_range(
            row,
            7,
            row,
            14,
            "Signature of Authorized Person over Printed Name, Designation",
            &formats.sig_caption,
        )
        .map_err(excel_err)?;
    row += 1;

    Ok(row)
}
